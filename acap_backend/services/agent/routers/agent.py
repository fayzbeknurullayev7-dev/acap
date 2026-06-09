"""
Agent router.

REST:
  POST /agent/tasks             — submit a new task
  GET  /agent/tasks             — list running task ids (Redis-backed)
  GET  /agent/tasks/{id}        — get task status
  POST /agent/tasks/{id}/cancel — cancel a running task

WebSocket:
  WS /agent/tasks/{id}/stream — real-time event stream
"""

import asyncio
import json
import logging
from typing import Optional

import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status

from core.dependencies import get_current_user_id
from core.redis import get_redis
from models.task import Task
from schemas.agent import CancelTaskRequest, RunTaskRequest, TaskResponse, TaskStatus
from services.event_publisher import subscribe
from services.orchestrator import Orchestrator

logger = logging.getLogger(__name__)
router = APIRouter()

# Running task'lar ro'yxati Redis'da saqlanadi (servislar orasida ko'rinadi).
_RUNNING_KEY = "acap:running_tasks"
_RUNNING_TTL = 86400  # 1 kun

# asyncio.Task handle'lari faqat shu jarayonda bekor qilish uchun saqlanadi
# (Redis'ga serializatsiya qilib bo'lmaydi).
_running_tasks: dict[str, asyncio.Task] = {}


# ── POST /agent/tasks ──────────────────────────────────────────────────────

@router.post("/tasks", status_code=status.HTTP_202_ACCEPTED)
async def submit_task(
    body: RunTaskRequest,
    user_id: str = Depends(get_current_user_id),
    redis: aioredis.Redis = Depends(get_redis),
) -> dict:
    task = Task(
        task_id=Task.new_id(),
        project_id=body.project_id,
        session_id=body.session_id,
        user_message=body.user_message,
        user_id=user_id,
        selected_agents=body.selected_agents,
    )
    await task.save(redis)

    # Redis registry — running task id'lar
    await redis.sadd(_RUNNING_KEY, task.task_id)
    await redis.expire(_RUNNING_KEY, _RUNNING_TTL)

    # Fire-and-forget in background
    orchestrator = Orchestrator(redis)
    bg = asyncio.create_task(orchestrator.execute(task))
    _running_tasks[task.task_id] = bg

    def _on_done(_: asyncio.Task) -> None:
        _running_tasks.pop(task.task_id, None)
        # add_done_callback sync chaqiriladi (event loop ichida) — create_task xavfsiz
        asyncio.create_task(redis.srem(_RUNNING_KEY, task.task_id))

    bg.add_done_callback(_on_done)

    logger.info("Task submitted: %s by user %s", task.task_id[:8], user_id[:8])
    return {"task_id": task.task_id, "status": "queued"}


# ── GET /agent/tasks ───────────────────────────────────────────────────────

@router.get("/tasks")
async def list_running_tasks(
    user_id: str = Depends(get_current_user_id),
    redis: aioredis.Redis = Depends(get_redis),
) -> dict:
    """Hozir ishlayotgan task id'lar ro'yxati (Redis set)."""
    members = await redis.smembers(_RUNNING_KEY)
    return {"tasks": sorted(members)}


# ── GET /agent/tasks/{task_id} ─────────────────────────────────────────────

@router.get("/tasks/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: str,
    user_id: str = Depends(get_current_user_id),
    redis: aioredis.Redis = Depends(get_redis),
) -> TaskResponse:
    task = await Task.load(redis, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    return TaskResponse(
        task_id=task.task_id,
        status=task.status,
        project_id=task.project_id,
        session_id=task.session_id,
        steps=task.steps,
        final_output=task.final_output,
        error=task.error,
    )


# ── POST /agent/tasks/{task_id}/cancel ────────────────────────────────────

@router.post("/tasks/{task_id}/cancel")
async def cancel_task(
    task_id: str,
    user_id: str = Depends(get_current_user_id),
    redis: aioredis.Redis = Depends(get_redis),
) -> dict:
    # Cancel the asyncio task if still running in this process
    bg = _running_tasks.get(task_id)
    if bg and not bg.done():
        bg.cancel()

    # Mark cancelled in Redis
    task = await Task.load(redis, task_id)
    if task:
        task.cancel()
        await task.save(redis)

    # Registry'dan olib tashlaymiz
    await redis.srem(_RUNNING_KEY, task_id)

    return {"task_id": task_id, "status": "cancelled"}


# ── WS /agent/tasks/{task_id}/stream ──────────────────────────────────────

@router.websocket("/tasks/{task_id}/stream")
async def stream_task(
    websocket: WebSocket,
    task_id: str,
    token: Optional[str] = None,
    redis: aioredis.Redis = Depends(get_redis),
):
    """
    WebSocket endpoint.
    Client connects, receives all events for task_id in real-time.
    Connection closes automatically when TASK_DONE / TASK_ERROR / TASK_CANCELLED arrives.
    """
    await websocket.accept()
    logger.info("[WS] Client connected to task %s", task_id[:8])

    terminal_events = {"task.done", "task.error", "task.cancelled"}

    try:
        async for event_data in subscribe(redis, task_id):
            try:
                await websocket.send_text(json.dumps(event_data))
            except Exception:
                break

            # Close after terminal event
            if event_data.get("type") in terminal_events:
                break

    except WebSocketDisconnect:
        logger.info("[WS] Client disconnected from task %s", task_id[:8])
    except Exception as exc:
        logger.error("[WS] Error for task %s: %s", task_id[:8], exc)
    finally:
        try:
            await websocket.close()
        except Exception:
            pass
