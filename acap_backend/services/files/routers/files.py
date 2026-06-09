# filename: acap_backend/services/files/routers/files.py
from typing import Annotated

from fastapi import APIRouter, Depends

from core.dependencies import get_current_user_id
from schemas.file import (
    DeleteResponse,
    FileContentResponse,
    FileListResponse,
    FileSavedResponse,
    FileWriteRequest,
    SuggestRequest,
    SuggestResponse,
)
from services.file_service import FileService

router = APIRouter()

CurrentUserId = Annotated[str, Depends(get_current_user_id)]


def get_service() -> FileService:
    return FileService()


# ── GET /files/{project_id} — recursive listing ─────────────────────────────

@router.get("/{project_id}", response_model=FileListResponse)
async def list_files(
    project_id: str,
    user_id: CurrentUserId,
    service: FileService = Depends(get_service),
):
    return FileListResponse(files=service.list_files(project_id))


# ── POST /files/{project_id}/suggest — LLM code completion ───────────────────
# NOTE: catch-all'dan oldin e'lon qilinadi.

@router.post("/{project_id}/suggest", response_model=SuggestResponse)
async def suggest(
    project_id: str,
    body: SuggestRequest,
    user_id: CurrentUserId,
    service: FileService = Depends(get_service),
):
    suggestion = await service.suggest(body.content, body.cursor_position)
    return SuggestResponse(suggestion=suggestion)


# ── GET /files/{project_id}/{file_path} — read content ──────────────────────

@router.get("/{project_id}/{file_path:path}", response_model=FileContentResponse)
async def read_file(
    project_id: str,
    file_path: str,
    user_id: CurrentUserId,
    service: FileService = Depends(get_service),
):
    return service.read_file(project_id, file_path)


# ── PUT /files/{project_id}/{file_path} — write / create ────────────────────

@router.put("/{project_id}/{file_path:path}", response_model=FileSavedResponse)
async def write_file(
    project_id: str,
    file_path: str,
    body: FileWriteRequest,
    user_id: CurrentUserId,
    service: FileService = Depends(get_service),
):
    return service.write_file(project_id, file_path, body.content)


# ── DELETE /files/{project_id}/{file_path} ──────────────────────────────────

@router.delete("/{project_id}/{file_path:path}", response_model=DeleteResponse)
async def delete_file(
    project_id: str,
    file_path: str,
    user_id: CurrentUserId,
    service: FileService = Depends(get_service),
):
    rel_path = service.delete_file(project_id, file_path)
    return DeleteResponse(deleted=True, path=rel_path)
