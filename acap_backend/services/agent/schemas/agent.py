"""Pydantic schemas for Agent Orchestrator API."""

from __future__ import annotations

from enum import Enum
from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


# ── Enums ───────────────────────────────────────────────────────────────────

class AgentType(str, Enum):
    PLANNER      = "planner"
    ARCHITECT    = "architect"
    CODER        = "coder"
    REVIEWER     = "reviewer"
    TESTER       = "tester"
    DEBUGGER     = "debugger"
    DEVOPS       = "devops"
    DOCUMENTATION= "documentation"
    SECURITY     = "security"
    PRODUCT      = "product"


class AgentStatus(str, Enum):
    IDLE      = "idle"
    RUNNING   = "running"
    WAITING   = "waiting"
    DONE      = "done"
    ERROR     = "error"
    SKIPPED   = "skipped"


class TaskStatus(str, Enum):
    QUEUED     = "queued"
    PLANNING   = "planning"
    RUNNING    = "running"
    REVIEWING  = "reviewing"
    DONE       = "done"
    ERROR      = "error"
    CANCELLED  = "cancelled"


# ── Request / Response ──────────────────────────────────────────────────────

class RunTaskRequest(BaseModel):
    project_id: str
    session_id: str
    user_message: str
    context: Optional[Dict[str, Any]] = Field(default_factory=dict)
    selected_agents: Optional[List[AgentType]] = None  # None = auto-select


class CancelTaskRequest(BaseModel):
    task_id: str


class AgentStepInfo(BaseModel):
    agent: AgentType
    status: AgentStatus
    message: str = ""
    output: Optional[str] = None
    started_at: Optional[str] = None
    finished_at: Optional[str] = None
    tool_calls: List[Dict[str, Any]] = Field(default_factory=list)


class TaskResponse(BaseModel):
    task_id: str
    status: TaskStatus
    project_id: str
    session_id: str
    steps: List[AgentStepInfo] = Field(default_factory=list)
    final_output: Optional[str] = None
    error: Optional[str] = None


# ── WebSocket event frames ──────────────────────────────────────────────────

class WsEventType(str, Enum):
    TASK_STARTED    = "task.started"
    AGENT_STARTED   = "agent.started"
    AGENT_THINKING  = "agent.thinking"
    AGENT_TOOL_CALL = "agent.tool_call"
    AGENT_TOOL_RESULT = "agent.tool_result"
    AGENT_DELTA     = "agent.delta"
    AGENT_DONE      = "agent.done"
    AGENT_ERROR     = "agent.error"
    TASK_DONE       = "task.done"
    TASK_ERROR      = "task.error"
    TASK_CANCELLED  = "task.cancelled"


class WsEvent(BaseModel):
    type: WsEventType
    task_id: str
    agent: Optional[AgentType] = None
    data: Dict[str, Any] = Field(default_factory=dict)
