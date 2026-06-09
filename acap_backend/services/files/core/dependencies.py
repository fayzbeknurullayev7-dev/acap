# filename: acap_backend/services/files/core/dependencies.py
"""Auth dependency — validates JWT locally (same pattern as agent-service)."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

from core.config import settings

_bearer = HTTPBearer()


async def get_current_user_id(
    creds: HTTPAuthorizationCredentials = Depends(_bearer),
) -> str:
    try:
        payload = jwt.decode(
            creds.credentials,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
        user_id: str = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
            )
        return user_id
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )
