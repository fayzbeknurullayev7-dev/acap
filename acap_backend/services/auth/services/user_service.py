from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from models.user import User


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: str | UUID) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.email == email.lower())
        )
        return result.scalar_one_or_none()

    async def get_by_provider(
        self, provider: str, provider_id: str
    ) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(
                User.provider == provider,
                User.provider_id == provider_id,
            )
        )
        return result.scalar_one_or_none()

    async def create(
        self,
        email: str,
        name: str,
        provider: str = "email",
        provider_id: str = None,
        avatar_url: str = None,
        is_verified: bool = False,
    ) -> User:
        user = User(
            email=email.lower(),
            name=name,
            provider=provider,
            provider_id=provider_id,
            avatar_url=avatar_url,
            is_verified=is_verified,
        )
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def update_last_login(self, user_id: UUID):
        await self.db.execute(
            update(User)
            .where(User.id == user_id)
            .values(last_login_at=datetime.now(timezone.utc))
        )

    async def verify_user(self, user_id: UUID):
        await self.db.execute(
            update(User)
            .where(User.id == user_id)
            .values(is_verified=True)
        )

    async def update_profile(
        self,
        user_id: UUID,
        name: str = None,
        avatar_url: str = None,
    ) -> Optional[User]:
        values = {}
        if name:
            values["name"] = name
        if avatar_url:
            values["avatar_url"] = avatar_url
        if not values:
            return await self.get_by_id(user_id)

        await self.db.execute(
            update(User).where(User.id == user_id).values(**values)
        )
        return await self.get_by_id(user_id)
