from datetime import datetime, timezone, timedelta

from loguru import logger

from core.config import settings
from core.redis_client import redis_client
from core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
)
from models.user import User
from schemas.auth_schemas import TokenResponse


class TokenService:

    async def create_token_pair(self, user: User) -> TokenResponse:
        access_token, access_jti = create_access_token(
            sub=str(user.id),
            email=user.email,
            role=user.role,
            tier=user.tier,
        )
        refresh_token, refresh_jti = create_refresh_token(sub=str(user.id))

        expires_at = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

        # Cache refresh JTI in Redis for rotation validation
        await redis_client.set(
            f"refresh_jti:{str(user.id)}",
            refresh_jti,
            ttl=settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400,
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_at=expires_at,
        )

    async def refresh_tokens(
        self, refresh_token: str, user: User
    ) -> TokenResponse:
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise ValueError("Invalid refresh token")

        jti = payload.get("jti")

        # Rotation check — only the last issued refresh token is valid
        stored_jti = await redis_client.get(f"refresh_jti:{str(user.id)}")
        if stored_jti != jti:
            # Token reuse detected — revoke all sessions
            await self.revoke_all(str(user.id))
            raise ValueError("Refresh token reuse detected")

        # Blacklist old JTI
        await redis_client.blacklist_token(jti, ttl=settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400)

        return await self.create_token_pair(user)

    async def revoke_access_token(self, token: str):
        payload = decode_token(token)
        if not payload:
            return
        jti = payload.get("jti")
        exp = payload.get("exp")
        if jti and exp:
            ttl = max(0, exp - int(datetime.now(timezone.utc).timestamp()))
            await redis_client.blacklist_token(jti, ttl=ttl)

    async def revoke_all(self, user_id: str):
        """Revoke all sessions for a user (on suspicious activity)"""
        await redis_client.delete(f"refresh_jti:{user_id}")
        await redis_client.delete_session(user_id)
        logger.warning(f"Revoked all sessions for user {user_id}")


token_service = TokenService()
