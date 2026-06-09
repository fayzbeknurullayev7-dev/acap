from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from core.config import settings
from core.database import engine, Base
from routers.terminal_router import router as terminal_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting ACAP Terminal Service...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("DB ready")
    yield
    await engine.dispose()
    logger.info("Terminal Service stopped")


app = FastAPI(
    title="ACAP Terminal Service",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(terminal_router, prefix="/api/v1/terminal", tags=["Terminal"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "terminal"}
