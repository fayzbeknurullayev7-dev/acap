import asyncio
import json
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from jose import JWTError, jwt
from loguru import logger

from core.config import settings
from services.pty_service import pty_manager

router = APIRouter()


# ── JWT validation for WebSocket (can't use Bearer header in WS) ──────────

async def get_user_from_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        if payload.get("type") != "access":
            return None
        return payload
    except JWTError:
        return None


# ── WebSocket Terminal ────────────────────────────────────────────────────

@router.websocket("/{session_id}")
async def terminal_ws(
    websocket: WebSocket,
    session_id: str,
    token: str = Query(...),
    project_id: str = Query(...),
):
    # Auth
    user = await get_user_from_token(token)
    if not user:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    user_id = user["sub"]

    await websocket.accept()
    logger.info(f"Terminal WS connected: session={session_id} user={user_id}")

    # Check session limit
    user_sessions = pty_manager.get_user_sessions(user_id)
    if len(user_sessions) >= settings.MAX_SESSIONS_USER:
        await websocket.send_json({
            "type":    "error",
            "message": f"Max {settings.MAX_SESSIONS_USER} terminal sessions allowed",
        })
        await websocket.close()
        return

    # Output callback → send to WebSocket
    async def on_output(sid: str, data: str):
        if sid == session_id:
            try:
                await websocket.send_json({"type": "output", "data": data})
            except Exception:
                pass

    def on_output_sync(sid: str, data: str):
        asyncio.create_task(on_output(sid, data))

    def on_exit(sid: str, code: int):
        asyncio.create_task(
            websocket.send_json({"type": "exit", "code": code})
        )

    # Create PTY session
    project_path = f"/workspaces/{user_id}/{project_id}"
    import os
    os.makedirs(project_path, exist_ok=True)

    session = pty_manager.create_session(
        project_path=project_path,
        user_id=user_id,
        on_output=on_output_sync,
        on_exit=on_exit,
    )

    # Start read loop
    read_task = asyncio.create_task(session.read_loop())

    # Notify client
    await websocket.send_json({
        "type":    "connected",
        "session": session.session_id,
    })

    try:
        while True:
            raw = await websocket.receive_text()
            msg = json.loads(raw)
            msg_type = msg.get("type")

            if msg_type == "input":
                session.write(msg.get("data", ""))

            elif msg_type == "resize":
                session.resize(
                    cols=msg.get("cols", settings.PTY_COLS),
                    rows=msg.get("rows", settings.PTY_ROWS),
                )

            elif msg_type == "ping":
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        logger.info(f"Terminal WS disconnected: session={session_id}")
    except Exception as e:
        logger.error(f"Terminal WS error: {e}")
    finally:
        read_task.cancel()
        pty_manager.close_session(session.session_id)


# ── REST: List & close sessions ───────────────────────────────────────────

@router.get("/sessions")
async def list_sessions(token: str = Query(...)):
    user = await get_user_from_token(token)
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")

    sessions = pty_manager.get_user_sessions(user["sub"])
    return [
        {
            "session_id": s.session_id,
            "project_path": s.project_path,
            "created_at": s.created_at.isoformat(),
            "last_activity": s.last_activity.isoformat(),
        }
        for s in sessions
    ]


@router.delete("/sessions/{session_id}")
async def close_session(session_id: str, token: str = Query(...)):
    user = await get_user_from_token(token)
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")

    session = pty_manager.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.user_id != user["sub"]:
        raise HTTPException(status_code=403, detail="Not your session")

    pty_manager.close_session(session_id)
    return {"message": "Session closed"}
