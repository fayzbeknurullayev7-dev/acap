from fastapi import APIRouter
from dependencies.auth_deps import CurrentUser
from schemas.auth_schemas import UserResponse

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: CurrentUser):
    return UserResponse.model_validate(current_user)
