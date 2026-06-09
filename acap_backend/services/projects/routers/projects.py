# filename: acap_backend/services/projects/routers/projects.py
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.database import get_db
from core.dependencies import get_current_user_id
from schemas.project import (
    ProjectCreate,
    ProjectListResponse,
    ProjectResponse,
    ProjectUpdate,
)
from services.project_service import ProjectService

router = APIRouter()

CurrentUserId = Annotated[str, Depends(get_current_user_id)]
DbSession = Annotated[AsyncSession, Depends(get_db)]


async def _get_owned_project(
    project_id: UUID,
    user_id: str,
    db: AsyncSession,
):
    """Projectni topadi va egaligini tekshiradi (404 / 403)."""
    service = ProjectService(db)
    project = await service.get_by_id(project_id)
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found",
        )
    if project.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this project",
        )
    return project, service


# ── GET /projects ───────────────────────────────────────────────────────────

@router.get("", response_model=ProjectListResponse)
async def list_projects(user_id: CurrentUserId, db: DbSession):
    service = ProjectService(db)
    projects = await service.list_by_user(user_id)
    items = [ProjectResponse.model_validate(p) for p in projects]
    return ProjectListResponse(items=items, total=len(items))


# ── POST /projects ──────────────────────────────────────────────────────────

@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(
    body: ProjectCreate,
    user_id: CurrentUserId,
    db: DbSession,
):
    service = ProjectService(db)
    project = await service.create(user_id, body)
    return ProjectResponse.model_validate(project)


# ── GET /projects/{project_id} ──────────────────────────────────────────────

@router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(project_id: UUID, user_id: CurrentUserId, db: DbSession):
    project, _ = await _get_owned_project(project_id, user_id, db)
    return ProjectResponse.model_validate(project)


# ── PATCH /projects/{project_id} ────────────────────────────────────────────

@router.patch("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: UUID,
    body: ProjectUpdate,
    user_id: CurrentUserId,
    db: DbSession,
):
    project, service = await _get_owned_project(project_id, user_id, db)
    updated = await service.update(project, body)
    return ProjectResponse.model_validate(updated)


# ── DELETE /projects/{project_id} ───────────────────────────────────────────

@router.delete("/{project_id}")
async def delete_project(project_id: UUID, user_id: CurrentUserId, db: DbSession):
    project, service = await _get_owned_project(project_id, user_id, db)
    await service.delete(project)
    return {"deleted": True}
