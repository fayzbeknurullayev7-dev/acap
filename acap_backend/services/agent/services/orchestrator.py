"""
Orchestrator Service.

Executes the agent DAG produced by the Planner.
Each parallel_group is run concurrently; groups execute sequentially.
Events are published to Redis pub/sub for WebSocket forwarding.
"""

from __future__ import annotations

import asyncio
import logging
from typing import Any, Dict, List, Optional

import redis.asyncio as aioredis

from agents.factory import get_agent
from models.task import Task
from schemas.agent import AgentStatus, AgentType, TaskStatus, WsEventType
from services.event_publisher import publish

logger = logging.getLogger(__name__)


class Orchestrator:
    def __init__(self, redis: aioredis.Redis):
        self.redis = redis

    async def execute(self, task: Task):
        """Main entry point — runs the full agent pipeline for a task."""
        logger.info("Orchestrator.execute task=%s", task.task_id[:8])

        await publish(
            self.redis, task.task_id, WsEventType.TASK_STARTED,
            data={"message": task.user_message},
        )

        try:
            # ── Step 1: Run Planner ──────────────────────────────────────
            plan = await self._run_planner(task)
            if task.is_cancelled:
                return await self._finish_cancelled(task)

            if plan is None:
                # Planner failed — fallback single-coder run
                plan = {
                    "summary": task.user_message[:80],
                    "parallel_groups": [["coder"]],
                    "context_per_agent": {"coder": task.user_message},
                }

            # Attach per-agent context to task (agents read from here)
            task._agent_context = plan.get("context_per_agent", {})

            # ── Step 2: Execute parallel groups sequentially ─────────────
            groups: List[List[str]] = plan.get("parallel_groups", [["coder"]])

            for group_idx, group in enumerate(groups):
                if task.is_cancelled:
                    return await self._finish_cancelled(task)

                agent_types = [AgentType(a) for a in group if a != "planner"]
                if not agent_types:
                    continue

                logger.info(
                    "Executing group %d/%d: %s",
                    group_idx + 1, len(groups),
                    [a.value for a in agent_types],
                )

                # Run agents in this group concurrently
                results = await asyncio.gather(
                    *[self._run_agent(task, at) for at in agent_types],
                    return_exceptions=True,
                )

                # Store coder output for downstream agents
                for at, result in zip(agent_types, results):
                    if isinstance(result, dict) and at == AgentType.CODER:
                        task._coder_output = result.get("content", "")

            # ── Step 3: Finalise ─────────────────────────────────────────
            task.status = TaskStatus.DONE
            task.final_output = plan.get("summary", "Task completed.")
            await task.save(self.redis)

            await publish(
                self.redis, task.task_id, WsEventType.TASK_DONE,
                data={"summary": task.final_output},
            )

        except asyncio.CancelledError:
            await self._finish_cancelled(task)
        except Exception as exc:
            logger.exception("Orchestrator error: %s", exc)
            task.status = TaskStatus.ERROR
            task.error = str(exc)
            await task.save(self.redis)
            await publish(
                self.redis, task.task_id, WsEventType.TASK_ERROR,
                data={"error": str(exc)},
            )

    # ── Planner ────────────────────────────────────────────────────────────

    async def _run_planner(self, task: Task) -> Optional[Dict[str, Any]]:
        task.status = TaskStatus.PLANNING
        step = task.add_step(AgentType.PLANNER)

        await publish(
            self.redis, task.task_id, WsEventType.AGENT_STARTED,
            agent=AgentType.PLANNER,
            data={"message": "Analyzing task…"},
        )

        agent = get_agent(AgentType.PLANNER, task)
        plan = None

        try:
            async for event in agent.run():
                if task.is_cancelled:
                    return None
                if event["event"] == "thinking":
                    await publish(
                        self.redis, task.task_id, WsEventType.AGENT_THINKING,
                        agent=AgentType.PLANNER,
                        data={"text": event["data"].get("text", "")},
                    )
                elif event["event"] == "done":
                    plan = event["data"].get("plan")

            step.status = AgentStatus.DONE
            step.output = str(plan)
        except Exception as exc:
            step.status = AgentStatus.ERROR
            step.message = str(exc)
            logger.error("Planner error: %s", exc)

        await task.save(self.redis)
        await publish(
            self.redis, task.task_id, WsEventType.AGENT_DONE,
            agent=AgentType.PLANNER,
            data={"plan": plan},
        )
        return plan

    # ── Generic agent runner ───────────────────────────────────────────────

    async def _run_agent(self, task: Task, agent_type: AgentType) -> Dict[str, Any]:
        step = task.add_step(agent_type)
        step.status = AgentStatus.RUNNING

        await publish(
            self.redis, task.task_id, WsEventType.AGENT_STARTED,
            agent=agent_type,
            data={"message": f"{agent_type.value} started"},
        )

        agent = get_agent(agent_type, task)
        full_content = ""
        result: Dict[str, Any] = {}

        try:
            async for event in agent.run():
                if task.is_cancelled:
                    break

                ev = event["event"]
                data = event["data"]

                if ev == "delta":
                    full_content += data.get("text", "")
                    await publish(
                        self.redis, task.task_id, WsEventType.AGENT_DELTA,
                        agent=agent_type,
                        data=data,
                    )
                elif ev == "tool_call":
                    step.tool_calls.append(data)
                    await publish(
                        self.redis, task.task_id, WsEventType.AGENT_TOOL_CALL,
                        agent=agent_type,
                        data=data,
                    )
                elif ev == "tool_result":
                    await publish(
                        self.redis, task.task_id, WsEventType.AGENT_TOOL_RESULT,
                        agent=agent_type,
                        data=data,
                    )
                elif ev == "done":
                    result = data
                    full_content = data.get("content", full_content)

            step.status = AgentStatus.DONE
            step.output = full_content[:500]  # preview only

        except Exception as exc:
            step.status = AgentStatus.ERROR
            step.message = str(exc)
            logger.error("Agent %s error: %s", agent_type.value, exc)
            await publish(
                self.redis, task.task_id, WsEventType.AGENT_ERROR,
                agent=agent_type,
                data={"error": str(exc)},
            )

        await task.save(self.redis)
        await publish(
            self.redis, task.task_id, WsEventType.AGENT_DONE,
            agent=agent_type,
            data={"content_length": len(full_content)},
        )
        result["content"] = full_content
        return result

    # ── Helpers ────────────────────────────────────────────────────────────

    async def _finish_cancelled(self, task: Task):
        task.cancel()
        await task.save(self.redis)
        await publish(
            self.redis, task.task_id, WsEventType.TASK_CANCELLED,
            data={"message": "Task was cancelled"},
        )
