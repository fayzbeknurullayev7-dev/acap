from fastapi import APIRouter, Depends, HTTPException, Request, status
from loguru import logger
from sqlalchemy.ext.asyncio import AsyncSession

from core.config import settings
from core.database import get_db
from core.redis_client import redis_client
from core.security import generate_otp, hash_otp, verify_otp_hash
from dependencies.auth_deps import CurrentUser
from schemas.auth_schemas import (
    AuthResponse,
    GoogleTokenRequest,
    MessageResponse,
    OtpSendRequest,
    OtpSendResponse,
    OtpVerifyRequest,
    RefreshTokenRequest,
    TokenResponse,
    UserResponse,
)
from services.email_service import send_otp_email
from services.google_auth_service import google_auth_service
from services.token_service import token_service
from services.user_service import UserService

router = APIRouter()


# ── Google OAuth ──────────────────────────────────────────────────────────

@router.post(
    "/google/token",
    response_model=AuthResponse,
    summary="Exchange Google ID token for ACAP JWT",
)
async def google_token(
    body: GoogleTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    # 1. Verify with Google
    google_user = await google_auth_service.verify_id_token(body.id_token)
    if not google_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google token",
        )

    user_service = UserService(db)

    # 2. Find or create user
    user = await user_service.get_by_provider("google", google_user["sub"])
    if not user:
        # Check if email already exists (link accounts)
        user = await user_service.get_by_email(google_user["email"])
        if user:
            # Link Google to existing account
            user.provider_id = google_user["sub"]
            user.provider = "google"
            user.is_verified = True
        else:
            user = await user_service.create(
                email=google_user["email"],
                name=google_user["name"],
                provider="google",
                provider_id=google_user["sub"],
                avatar_url=google_user.get("picture"),
                is_verified=True,
            )

    await user_service.update_last_login(user.id)
    tokens = await token_service.create_token_pair(user)

    return AuthResponse(tokens=tokens, user=UserResponse.model_validate(user))


# ── OTP ───────────────────────────────────────────────────────────────────

@router.post(
    "/otp/send",
    response_model=OtpSendResponse,
    summary="Send 6-digit OTP to email",
)
async def send_otp(
    body: OtpSendRequest,
    request: Request,
):
    email = body.email.lower()

    # Check if blocked
    if await redis_client.is_otp_blocked(email):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many attempts. Please try again later.",
        )

    otp = generate_otp()
    otp_hash = hash_otp(otp, email)

    await redis_client.save_otp(
        email, "login",
        {"hash": otp_hash, "attempts": 0},
    )

    # Send email (fire and forget in prod — use background tasks)
    try:
        await send_otp_email(email, otp)
    except Exception as e:
        logger.error(f"Email send failed: {e}")
        # In dev, log OTP to console
        if settings.DEBUG:
            logger.info(f"[DEV] OTP for {email}: {otp}")

    return OtpSendResponse(expires_in=settings.OTP_EXPIRE_SECONDS)


@router.post(
    "/otp/verify",
    response_model=AuthResponse,
    summary="Verify OTP and get JWT tokens",
)
async def verify_otp(
    body: OtpVerifyRequest,
    db: AsyncSession = Depends(get_db),
):
    email = body.email.lower()

    # Check block
    if await redis_client.is_otp_blocked(email):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many failed attempts. Please request a new OTP.",
        )

    # Get stored OTP
    otp_data = await redis_client.get_otp(email, "login")
    if not otp_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP expired or not found. Please request a new code.",
        )

    # Verify
    if not verify_otp_hash(body.otp, email, otp_data["hash"]):
        attempts = await redis_client.increment_otp_attempts(email)
        remaining = settings.OTP_MAX_ATTEMPTS - attempts
        if remaining <= 0:
            await redis_client.block_otp(email)
            await redis_client.delete_otp(email, "login")
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many failed attempts. Account temporarily blocked.",
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid OTP. {remaining} attempts remaining.",
        )

    # OTP valid — clean up
    await redis_client.delete_otp(email, "login")
    await redis_client.delete(f"otp_attempts:{email}")

    # Find or create user
    user_service = UserService(db)
    user = await user_service.get_by_email(email)
    if not user:
        name = email.split("@")[0].replace(".", " ").title()
        user = await user_service.create(
            email=email,
            name=name,
            provider="email",
            is_verified=True,
        )
    else:
        await user_service.verify_user(user.id)

    await user_service.update_last_login(user.id)
    tokens = await token_service.create_token_pair(user)

    return AuthResponse(tokens=tokens, user=UserResponse.model_validate(user))


# ── Token refresh / logout ────────────────────────────────────────────────

@router.post(
    "/token/refresh",
    response_model=TokenResponse,
    summary="Refresh access token using refresh token",
)
async def refresh_token(
    body: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    from core.security import decode_token

    payload = decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )

    user_id = payload.get("sub")
    user_service = UserService(db)
    user = await user_service.get_by_id(user_id)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or deactivated",
        )

    try:
        tokens = await token_service.refresh_tokens(body.refresh_token, user)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )

    return tokens


@router.post(
    "/logout",
    response_model=MessageResponse,
    summary="Logout and revoke tokens",
)
async def logout(
    current_user: CurrentUser,
    request: Request,
):
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
        await token_service.revoke_access_token(token)

    await redis_client.delete_session(str(current_user.id))
    return MessageResponse(message="Logged out successfully")
