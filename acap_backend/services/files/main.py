# filename: acap_backend/services/files/main.py
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from core.config import settings
from routers import files as files_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting ACAP Files Service...")
    yield
    logger.info("Files Service shut down")


app = FastAPI(
    title="ACAP Files Service",
    description="Disk-backed file storage for AI Coding Agent Platform",
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
app.include_router(files_router.router, prefix="/files", tags=["Files"])


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok", "service": "files"}
