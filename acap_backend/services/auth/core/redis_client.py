import json
from typing import Any, Optional

import redis.asyncio as aioredis
from loguru import logger

from core.config import settings


class RedisClient:
    _client: Optional[aioredis.Redis] = None

    async def connect(self):
        self._client = await aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
        )
        await self._client.ping()
        logger.info("Redis connection established")

    async def disconnect(self):
        if self._client:
            await self._client.aclose()

    def _ensure_connected(self):
        if not self._client:
            raise RuntimeError("Redis not connected")

    # ── Basic ops ────────────────────────────────────────────────

    async def get(self, key: str) -> Optional[str]:
        self._ensure_connected()
        return await self._client.get(key)

    async def set(self, key: str, value: str, ttl: int = None):
        self._ensure_connected()
        if ttl:
            await self._client.setex(key, ttl, value)
        else:
            await self._client.set(key, value)

    async def delete(self, key: str):
        self._ensure_connected()
        await self._client.delete(key)

    async def exists(self, key: str) -> bool:
        self._ensure_connected()
        return bool(await self._client.exists(key))

    async def incr(self, key: str) -> int:
        self._ensure_connected()
        return await self._client.incr(key)

    async def expire(self, key: str, ttl: int):
        self._ensure_connected()
        await self._client.expire(key, ttl)

    async def ttl(self, key: str) -> int:
        self._ensure_connected()
        return await self._client.ttl(key)

    # ── JSON helpers ─────────────────────────────────────────────

    async def set_json(self, key: str, value: Any, ttl: int = None):
        await self.set(key, json.dumps(value), ttl)

    async def get_json(self, key: str) -> Optional[Any]:
        raw = await self.get(key)
        return json.loads(raw) if raw else None

    # ── Session helpers ──────────────────────────────────────────

    async def save_session(self, user_id: str, data: dict, ttl: int = 86400):
        """Save user session (24h default)"""
        await self.set_json(f"session:{user_id}", data, ttl)

    async def get_session(self, user_id: str) -> Optional[dict]:
        return await self.get_json(f"session:{user_id}")

    async def delete_session(self, user_id: str):
        await self.delete(f"session:{user_id}")

    # ── OTP helpers ──────────────────────────────────────────────

    async def save_otp(self, email: str, purpose: str, data: dict):
        key = f"otp:{email}:{purpose}"
        await self.set_json(key, data, settings.OTP_EXPIRE_SECONDS)

    async def get_otp(self, email: str, purpose: str) -> Optional[dict]:
        return await self.get_json(f"otp:{email}:{purpose}")

    async def delete_otp(self, email: str, purpose: str):
        await self.delete(f"otp:{email}:{purpose}")

    async def get_otp_attempts(self, email: str) -> int:
        val = await self.get(f"otp_attempts:{email}")
        return int(val) if val else 0

    async def increment_otp_attempts(self, email: str) -> int:
        key = f"otp_attempts:{email}"
        count = await self.incr(key)
        if count == 1:
            await self.expire(key, settings.OTP_BLOCK_SECONDS)
        return count

    async def is_otp_blocked(self, email: str) -> bool:
        return await self.exists(f"otp_block:{email}")

    async def block_otp(self, email: str):
        await self.set(f"otp_block:{email}", "1", settings.OTP_BLOCK_SECONDS)

    # ── Rate limiting ────────────────────────────────────────────

    async def check_rate_limit(self, user_id: str, endpoint: str, limit: int) -> bool:
        """Returns True if request is allowed"""
        key = f"rate:{user_id}:{endpoint}"
        count = await self.incr(key)
        if count == 1:
            await self.expire(key, 60)  # 1 minute window
        return count <= limit

    # ── Refresh token blacklist ───────────────────────────────────

    async def blacklist_token(self, jti: str, ttl: int):
        await self.set(f"blacklist:{jti}", "1", ttl)

    async def is_token_blacklisted(self, jti: str) -> bool:
        return await self.exists(f"blacklist:{jti}")


redis_client = RedisClient()
