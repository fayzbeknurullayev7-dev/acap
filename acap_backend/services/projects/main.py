# filename: acap_backend/services/projects/main.py
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from core.config import settings
from core.database import engine, Base
from routers import projects as projects_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Startup ──────────────────────────────────────────────────
    logger.info("Starting ACAP Projects Service...")

    # Create DB tables (in prod use Alembic migrations)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables ready")

    yield

    # ── Shutdown ─────────────────────────────────────────────────
    await engine.dispose()
    logger.info("Projects Service shut down")


app = FastAPI(
    title="ACAP Projects Service",
    description="Project management for AI Coding Agent Platform",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# ── Middleware ────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────
app.include_router(projects_router.router, prefix="/projects", tags=["Projects"])


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok", "service": "projects"}
