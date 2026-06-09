# filename: acap_backend/services/projects/services/project_service.py
import os
import shutil
from typing import Optional, Sequence
from uuid import UUID

from loguru import logger
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.config import settings
from models.project import Project
from schemas.project import ProjectCreate, ProjectUpdate


class ProjectService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Queries ──────────────────────────────────────────────────
    async def list_by_user(self, user_id: str) -> Sequence[Project]:
        result = await self.db.execute(
            select(Project)
            .where(Project.user_id == user_id)
            .order_by(Project.last_activity.desc())
        )
        return result.scalars().all()

    async def get_by_id(self, project_id: UUID | str) -> Optional[Project]:
        result = await self.db.execute(
            select(Project).where(Project.id == project_id)
        )
        return result.scalar_one_or_none()

    # ── Mutations ────────────────────────────────────────────────
    async def create(self, user_id: str, data: ProjectCreate) -> Project:
        project = Project(
            user_id=user_id,
            name=data.name,
            description=data.description,
            language=data.language or "plaintext",
        )
        self.db.add(project)
        # id ni olish uchun flush qilamiz (gen_random_uuid())
        await self.db.flush()
        await self.db.refresh(project)

        # /workspaces/{project_id}/ papkasini yaratamiz
        workspace = os.path.join(settings.WORKSPACES_ROOT, str(project.id))
        os.makedirs(workspace, exist_ok=True)
        project.workspace_path = f"{workspace}{os.sep}"

        await self.db.flush()
        await self.db.refresh(project)
        logger.info("Project created: {} (user {})", project.id, user_id)
        return project

    async def update(self, project: Project, data: ProjectUpdate) -> Project:
        if data.name is not None:
            project.name = data.name
        if data.description is not None:
            project.description = data.description
        if data.language is not None:
            project.language = data.language
        # last_activity onupdate=now() orqali avtomatik yangilanadi
        await self.db.flush()
        await self.db.refresh(project)
        return project

    async def delete(self, project: Project) -> None:
        # /workspaces/{project_id}/ papkasini ham o'chiramiz
        workspace = os.path.join(settings.WORKSPACES_ROOT, str(project.id))
        if os.path.isdir(workspace):
            shutil.rmtree(workspace, ignore_errors=True)

        await self.db.delete(project)
        await self.db.flush()
        logger.info("Project deleted: {}", project.id)
