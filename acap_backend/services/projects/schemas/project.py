# filename: acap_backend/services/projects/schemas/project.py
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# ── Requests ────────────────────────────────────────────────────────────────

class ProjectCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    language: str = Field(default="plaintext", max_length=50)
    description: Optional[str] = None


class ProjectUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    description: Optional[str] = None
    language: Optional[str] = Field(default=None, max_length=50)


# ── Responses ───────────────────────────────────────────────────────────────

class ProjectResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: Optional[str] = None
    language: str
    workspace_path: Optional[str] = None
    created_at: datetime
    last_activity: datetime
    user_id: str


class ProjectListResponse(BaseModel):
    items: List[ProjectResponse]
    total: int
