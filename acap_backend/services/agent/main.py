"""
ACAP — Agent Orchestrator Service
FastAPI + LangGraph multi-agent coordination
"""

import logging
from contextlib import asynccontextmanager

import redis.asyncio as aioredis
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import settings
from core.redis import redis_pool
from routers import agent as agent_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Agent Orchestrator starting…")
    yield
    logger.info("Agent Orchestrator shutting down…")
    await redis_pool.aclose()


app = FastAPI(
    title="ACAP Agent Orchestrator",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(agent_router.router, prefix="/agent", tags=["agent"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "agent-orchestrator"}
