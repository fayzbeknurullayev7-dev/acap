from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )

    # ── App ──────────────────────────────────────────────────────
    APP_NAME: str = "ACAP Auth Service"
    DEBUG: bool = False
    ALLOWED_HOSTS: List[str] = ["*"]
    ALLOWED_ORIGINS: List[str] = ["*"]

    # ── Database ─────────────────────────────────────────────────
    DATABASE_URL: str = "postgresql+asyncpg://acap:acap_secret@localhost:5432/acap_db"

    # ── Redis ────────────────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379/0"

    # ── JWT ──────────────────────────────────────────────────────
    JWT_SECRET_KEY: str = "change-me-in-production-use-256-bit-random"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # ── Google OAuth ─────────────────────────────────────────────
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""

    # ── Email / OTP ──────────────────────────────────────────────
    MAIL_USERNAME: str = ""
    MAIL_PASSWORD: str = ""
    MAIL_FROM: str = "noreply@acap.dev"
    MAIL_SERVER: str = "smtp.gmail.com"
    MAIL_PORT: int = 587
    MAIL_TLS: bool = True
    MAIL_SSL: bool = False

    OTP_EXPIRE_SECONDS: int = 300       # 5 min
    OTP_MAX_ATTEMPTS: int = 5
    OTP_BLOCK_SECONDS: int = 600        # 10 min after max attempts

    # ── Rate Limiting ────────────────────────────────────────────
    RATE_LIMIT_FREE: int = 50           # req/min
    RATE_LIMIT_PRO: int = 500


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
