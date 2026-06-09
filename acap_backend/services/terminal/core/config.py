from functools import lru_cache
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)

    DEBUG: bool = False
    ALLOWED_ORIGINS: List[str] = ["*"]

    DATABASE_URL: str = "postgresql+asyncpg://acap:acap_secret@localhost:5432/acap_db"
    REDIS_URL:    str = "redis://localhost:6379/1"

    # Auth service for JWT validation
    AUTH_SERVICE_URL: str = "http://auth-service:8000"
    JWT_SECRET_KEY:   str = "change-me-in-production"
    JWT_ALGORITHM:    str = "HS256"

    # PTY settings
    PTY_SHELL:         str  = "/bin/bash"
    PTY_COLS:          int  = 220
    PTY_ROWS:          int  = 50
    PTY_TIMEOUT_SEC:   int  = 1800   # 30 min idle timeout
    MAX_SESSIONS_USER: int  = 3      # max concurrent terminals per user
    OUTPUT_BUFFER_KB:  int  = 64     # output buffer size


@lru_cache
def get_settings():
    return Settings()


settings = get_settings()
