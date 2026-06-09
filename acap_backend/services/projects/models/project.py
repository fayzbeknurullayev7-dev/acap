# filename: acap_backend/services/projects/models/project.py
import uuid
from datetime import datetime

from sqlalchemy import DateTime, String, Text, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base


class Project(Base):
    __tablename__ = "projects"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
        default=uuid.uuid4,
    )
    # JWT 'sub' dan olinadi (auth-service user id)
    user_id: Mapped[str] = mapped_column(String(255), nullable=False, index=True)

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    language: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="plaintext",
        server_default="plaintext",
    )

    # /workspaces/{id}/ — POST paytida avtomatik to'ldiriladi
    workspace_path: Mapped[str | None] = mapped_column(String(512), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    last_activity: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    def __repr__(self) -> str:
        return f"<Project {self.name} [{self.id}]>"
