# filename: acap_backend/services/projects/core/config.py
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # ── App ──────────────────────────────────────────────────────
    APP_NAME: str = "ACAP Projects Service"
    DEBUG: bool = False
    ALLOWED_HOSTS: List[str] = ["*"]
    ALLOWED_ORIGINS: List[str] = ["*"]

    # ── Database ─────────────────────────────────────────────────
    DATABASE_URL: str = "postgresql+asyncpg://acap:acap_secret@localhost:5432/acap_db"

    # ── Redis (parity with other services; optional) ─────────────
    REDIS_URL: str = "redis://localhost:6379/0"

    # ── JWT (local decode — same as auth-service) ────────────────
    JWT_SECRET_KEY: str = "change-me-in-production-use-256-bit-random"
    JWT_ALGORITHM: str = "HS256"

    # ── Workspaces ───────────────────────────────────────────────
    WORKSPACES_ROOT: str = "/workspaces"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
