"""
WS Event Publisher.
Publishes events to a Redis channel: acap:agent:events:{task_id}
The WebSocket router subscribes and forwards frames to clients.
"""

import json
import logging
from typing import Any, Dict, Optional

import redis.asyncio as aioredis

from schemas.agent import AgentType, WsEvent, WsEventType

logger = logging.getLogger(__name__)

_CHANNEL_PREFIX = "acap:agent:events:"


def _channel(task_id: str) -> str:
    return f"{_CHANNEL_PREFIX}{task_id}"


async def publish(
    redis: aioredis.Redis,
    task_id: str,
    event_type: WsEventType,
    agent: Optional[AgentType] = None,
    data: Optional[Dict[str, Any]] = None,
):
    event = WsEvent(
        type=event_type,
        task_id=task_id,
        agent=agent,
        data=data or {},
    )
    payload = event.model_dump_json()
    await redis.publish(_channel(task_id), payload)
    logger.debug("[PUB] %s → %s", event_type, task_id[:8])


async def subscribe(redis: aioredis.Redis, task_id: str):
    """Async generator that yields WsEvent dicts from the pub/sub channel."""
    pubsub = redis.pubsub()
    await pubsub.subscribe(_channel(task_id))
    try:
        async for message in pubsub.listen():
            if message["type"] == "message":
                try:
                    yield json.loads(message["data"])
                except Exception as e:
                    logger.warning("Parse error in subscriber: %s", e)
    finally:
        await pubsub.unsubscribe(_channel(task_id))
        await pubsub.aclose()
