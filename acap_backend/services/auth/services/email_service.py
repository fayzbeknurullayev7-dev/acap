from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType
from loguru import logger
from pydantic import EmailStr

from core.config import settings

mail_config = ConnectionConfig(
    MAIL_USERNAME=settings.MAIL_USERNAME,
    MAIL_PASSWORD=settings.MAIL_PASSWORD,
    MAIL_FROM=settings.MAIL_FROM,
    MAIL_PORT=settings.MAIL_PORT,
    MAIL_SERVER=settings.MAIL_SERVER,
    MAIL_STARTTLS=settings.MAIL_TLS,
    MAIL_SSL_TLS=settings.MAIL_SSL,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True,
)

_mail = FastMail(mail_config)

OTP_EMAIL_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {{ font-family: Arial, sans-serif; background: #0F0F11; color: #FAFAFA; margin: 0; padding: 40px 20px; }}
    .container {{ max-width: 480px; margin: 0 auto; background: #18181B; border-radius: 16px; padding: 40px; border: 1px solid #3F3F46; }}
    .logo {{ font-size: 28px; font-weight: bold; color: #6366F1; margin-bottom: 8px; }}
    .subtitle {{ color: #A1A1AA; font-size: 14px; margin-bottom: 32px; }}
    .otp-box {{ background: #27272A; border: 2px solid #6366F1; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }}
    .otp-code {{ font-size: 42px; font-weight: bold; letter-spacing: 12px; color: #6366F1; font-family: monospace; }}
    .note {{ color: #A1A1AA; font-size: 13px; margin-top: 24px; line-height: 1.6; }}
    .footer {{ color: #52525B; font-size: 12px; margin-top: 32px; text-align: center; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">⚡ ACAP</div>
    <div class="subtitle">AI Coding Agent Platform</div>
    <p>Here is your one-time verification code:</p>
    <div class="otp-box">
      <div class="otp-code">{otp}</div>
    </div>
    <p class="note">
      This code expires in <strong>5 minutes</strong>.<br>
      If you did not request this, please ignore this email.
    </p>
    <div class="footer">© 2026 ACAP Team · noreply@acap.dev</div>
  </div>
</body>
</html>
"""


async def send_otp_email(email: str, otp: str):
    try:
        message = MessageSchema(
            subject="Your ACAP verification code",
            recipients=[email],
            body=OTP_EMAIL_TEMPLATE.format(otp=otp),
            subtype=MessageType.html,
        )
        await _mail.send_message(message)
        logger.info(f"OTP email sent to {email}")
    except Exception as e:
        logger.error(f"Failed to send OTP email to {email}: {e}")
        raise
