import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Enum, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    avatar_url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    # Auth provider: google | email
    provider: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="email",
    )
    provider_id: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Roles & tiers
    tier: Mapped[str] = mapped_column(
        Enum("free", "pro", "team", "enterprise", name="user_tier"),
        nullable=False,
        default="free",
        server_default="free",
    )
    role: Mapped[str] = mapped_column(
        Enum("user", "admin", name="user_role"),
        nullable=False,
        default="user",
        server_default="user",
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
    last_login_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    def __repr__(self) -> str:
        return f"<User {self.email} [{self.tier}]>"
