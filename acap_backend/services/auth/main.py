from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from loguru import logger

from core.config import settings
from core.database import engine, Base
from core.redis_client import redis_client
from routers import auth_router, user_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Startup ──────────────────────────────────────────────────
    logger.info("Starting ACAP Auth Service...")

    # Create DB tables (in prod use Alembic migrations)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables ready")

    # Connect Redis
    await redis_client.connect()
    logger.info("Redis connected")

    yield

    # ── Shutdown ─────────────────────────────────────────────────
    await redis_client.disconnect()
    await engine.dispose()
    logger.info("Auth Service shut down")


app = FastAPI(
    title="ACAP Auth Service",
    description="Authentication & authorization for AI Coding Agent Platform",
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

if not settings.DEBUG:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=settings.ALLOWED_HOSTS,
    )

# ── Routers ───────────────────────────────────────────────────────────────

app.include_router(auth_router.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(user_router.router, prefix="/api/v1/auth", tags=["User"])


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok", "service": "auth"}
