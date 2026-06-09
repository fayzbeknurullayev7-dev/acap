import hashlib
import hmac
import random
import string
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from loguru import logger
from passlib.context import CryptContext

from core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Password ──────────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# ── JWT ───────────────────────────────────────────────────────────────────

def create_access_token(
    sub: str,
    email: str,
    role: str,
    tier: str,
    extra: dict = None,
) -> tuple[str, str]:
    """
    Returns (token, jti)
    """
    jti = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    exp = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    payload = {
        "sub":   sub,
        "email": email,
        "role":  role,
        "tier":  tier,
        "jti":   jti,
        "iat":   now,
        "exp":   exp,
        "type":  "access",
    }
    if extra:
        payload.update(extra)

    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token, jti


def create_refresh_token(sub: str) -> tuple[str, str]:
    """
    Returns (token, jti)
    """
    jti = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    exp = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    payload = {
        "sub":  sub,
        "jti":  jti,
        "iat":  now,
        "exp":  exp,
        "type": "refresh",
    }

    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token, jti


def decode_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
        return payload
    except JWTError as e:
        logger.warning(f"JWT decode error: {e}")
        return None


def get_token_expires_at(token: str) -> Optional[datetime]:
    payload = decode_token(token)
    if not payload:
        return None
    exp = payload.get("exp")
    return datetime.fromtimestamp(exp, tz=timezone.utc) if exp else None


# ── OTP ───────────────────────────────────────────────────────────────────

def generate_otp(length: int = 6) -> str:
    """Generate a numeric OTP"""
    return "".join(random.choices(string.digits, k=length))


def hash_otp(otp: str, email: str) -> str:
    """HMAC-SHA256 hash of OTP with email as key"""
    return hmac.new(
        email.encode(),
        otp.encode(),
        hashlib.sha256,
    ).hexdigest()


def verify_otp_hash(otp: str, email: str, stored_hash: str) -> bool:
    computed = hash_otp(otp, email)
    return hmac.compare_digest(computed, stored_hash)
