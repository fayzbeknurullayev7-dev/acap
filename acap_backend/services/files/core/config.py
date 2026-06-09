# filename: acap_backend/services/files/core/config.py
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
    APP_NAME: str = "ACAP Files Service"
    DEBUG: bool = False
    ALLOWED_ORIGINS: List[str] = ["*"]

    # ── JWT (local decode — same as auth-service) ────────────────
    JWT_SECRET_KEY: str = "change-me-in-production-use-256-bit-random"
    JWT_ALGORITHM: str = "HS256"

    # ── Workspaces ───────────────────────────────────────────────
    WORKSPACES_ROOT: str = "/workspaces"
    MAX_FILE_SIZE: int = 2 * 1024 * 1024  # 2 MB

    # ── LLM (GROQ) — code suggestions ────────────────────────────
    GROQ_API_KEY: str = ""
    GROQ_MODEL: str = "llama-3.3-70b-versatile"
    GROQ_BASE_URL: str = "https://api.groq.com/openai/v1"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
