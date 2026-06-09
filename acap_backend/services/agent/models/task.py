"""Task state model — stored in Redis as JSON."""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import redis.asyncio as aioredis

from schemas.agent import AgentStatus, AgentStepInfo, AgentType, TaskStatus

_KEY_PREFIX = "acap:task:"
_TTL_SECONDS = 3600  # 1 hour


class Task:
    """Mutable task state managed in Redis."""

    def __init__(
        self,
        task_id: str,
        project_id: str,
        session_id: str,
        user_message: str,
        user_id: str,
        selected_agents: Optional[List[AgentType]] = None,
    ):
        self.task_id = task_id
        self.project_id = project_id
        self.session_id = session_id
        self.user_message = user_message
        self.user_id = user_id
        self.selected_agents = selected_agents
        self.status = TaskStatus.QUEUED
        self.steps: List[AgentStepInfo] = []
        self.final_output: Optional[str] = None
        self.error: Optional[str] = None
        self.created_at = datetime.now(timezone.utc).isoformat()
        self._cancelled = False

    # ── Cancellation flag ─────────────────────────────────────────────────

    @property
    def is_cancelled(self) -> bool:
        return self._cancelled

    def cancel(self):
        self._cancelled = True
        self.status = TaskStatus.CANCELLED

    # ── Step helpers ──────────────────────────────────────────────────────

    def add_step(self, agent: AgentType) -> AgentStepInfo:
        step = AgentStepInfo(
            agent=agent,
            status=AgentStatus.IDLE,
            started_at=datetime.now(timezone.utc).isoformat(),
        )
        self.steps.append(step)
        return step

    def get_step(self, agent: AgentType) -> Optional[AgentStepInfo]:
        for s in reversed(self.steps):
            if s.agent == agent:
                return s
        return None

    def update_step(self, agent: AgentType, **kwargs):
        step = self.get_step(agent)
        if step:
            for k, v in kwargs.items():
                setattr(step, k, v)

    # ── Serialisation ─────────────────────────────────────────────────────

    def to_dict(self) -> Dict[str, Any]:
        return {
            "task_id": self.task_id,
            "project_id": self.project_id,
            "session_id": self.session_id,
            "user_message": self.user_message,
            "user_id": self.user_id,
            "status": self.status.value,
            "steps": [s.model_dump() for s in self.steps],
            "final_output": self.final_output,
            "error": self.error,
            "created_at": self.created_at,
            "cancelled": self._cancelled,
        }

    async def save(self, redis: aioredis.Redis):
        await redis.setex(
            f"{_KEY_PREFIX}{self.task_id}",
            _TTL_SECONDS,
            json.dumps(self.to_dict()),
        )

    @classmethod
    async def load(cls, redis: aioredis.Redis, task_id: str) -> Optional["Task"]:
        raw = await redis.get(f"{_KEY_PREFIX}{task_id}")
        if not raw:
            return None
        data = json.loads(raw)
        task = cls(
            task_id=data["task_id"],
            project_id=data["project_id"],
            session_id=data["session_id"],
            user_message=data["user_message"],
            user_id=data["user_id"],
        )
        task.status = TaskStatus(data["status"])
        task.steps = [AgentStepInfo(**s) for s in data.get("steps", [])]
        task.final_output = data.get("final_output")
        task.error = data.get("error")
        task._cancelled = data.get("cancelled", False)
        return task

    @staticmethod
    def new_id() -> str:
        return str(uuid.uuid4())
