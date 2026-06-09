from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator


# ── Requests ──────────────────────────────────────────────────────────────

class GoogleTokenRequest(BaseModel):
    id_token: str = Field(..., description="Google ID token from mobile client")


class OtpSendRequest(BaseModel):
    email: EmailStr


class OtpVerifyRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class RefreshTokenRequest(BaseModel):
    refresh_token: str


# ── Responses ─────────────────────────────────────────────────────────────

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_at: datetime


class UserResponse(BaseModel):
    id: UUID
    email: str
    name: str
    avatar_url: Optional[str] = None
    tier: str
    role: str
    is_verified: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class AuthResponse(BaseModel):
    tokens: TokenResponse
    user: UserResponse


class MessageResponse(BaseModel):
    message: str
    detail: Optional[str] = None


class OtpSendResponse(BaseModel):
    message: str = "OTP sent successfully"
    expires_in: int  # seconds
