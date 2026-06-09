"""Core configuration for Agent Orchestrator.

LLM providerlar: Groq (asosiy), Gemini (ikkinchi), Ollama (fallback).
ANTHROPIC ishlatilmaydi.
"""

from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # ── Service ──────────────────────────────────────────────────────────────
    SERVICE_NAME: str = "agent-orchestrator"
    DEBUG: bool = False

    # ── Redis (task queue + pub/sub) ─────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379/1"

    # ── Auth service (for token validation) ──────────────────────────────────
    AUTH_SERVICE_URL: str = "http://auth-service:8000"
    JWT_SECRET_KEY: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"

    # ── LLM Providers ────────────────────────────────────────────────────────
    # Tartib (avtomatik fallback): Groq → Gemini → Ollama
    PRIMARY_PROVIDER: str = "groq"            # groq | gemini | ollama

    GROQ_API_KEY: str = ""
    GROQ_MODEL: str = "llama-3.3-70b-versatile"

    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.0-flash"

    OLLAMA_BASE_URL: str = ""                 # HuggingFace endpoint, masalan https://xxx.hf.space
    OLLAMA_MODEL: str = "qwen2.5-coder:7b"

    # ── CORS ─────────────────────────────────────────────────────────────────
    ALLOWED_ORIGINS: List[str] = ["*"]

    # ── Agent limits ─────────────────────────────────────────────────────────
    MAX_AGENT_STEPS: int = 30
    AGENT_TIMEOUT_SECONDS: int = 300
    MAX_PARALLEL_AGENTS: int = 5
    MAX_TOOL_ITERATIONS: int = 5              # agentic tool-loop iteratsiyalari

    # ── Stream ───────────────────────────────────────────────────────────────
    STREAM_CHUNK_SIZE: int = 50               # chars per WS frame


settings = Settings()
