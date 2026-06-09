from typing import Optional

import httpx
from loguru import logger

from core.config import settings

GOOGLE_CERTS_URL = "https://www.googleapis.com/oauth2/v3/certs"
GOOGLE_TOKEN_INFO_URL = "https://oauth2.googleapis.com/tokeninfo"


class GoogleAuthService:
    """Verify Google ID tokens without the google-auth library overhead."""

    async def verify_id_token(self, id_token: str) -> Optional[dict]:
        """
        Returns user info dict if token is valid, None otherwise.
        Keys: sub, email, name, picture, email_verified
        """
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(
                    GOOGLE_TOKEN_INFO_URL,
                    params={"id_token": id_token},
                )

            if resp.status_code != 200:
                logger.warning(f"Google token verification failed: {resp.text}")
                return None

            data = resp.json()

            # Validate audience
            if data.get("aud") != settings.GOOGLE_CLIENT_ID:
                logger.warning("Google token audience mismatch")
                return None

            if not data.get("email_verified"):
                logger.warning("Google email not verified")
                return None

            return {
                "sub":            data["sub"],
                "email":          data["email"],
                "name":           data.get("name", data["email"].split("@")[0]),
                "picture":        data.get("picture"),
                "email_verified": data.get("email_verified", False),
            }

        except Exception as e:
            logger.error(f"Google token verification error: {e}")
            return None


google_auth_service = GoogleAuthService()
