# filename: acap_backend/services/files/schemas/file.py
from typing import List, Optional

from pydantic import BaseModel, Field


# ── File metadata / content ─────────────────────────────────────────────────

class FileInfo(BaseModel):
    id: str                 # path ni base64 qilingan ko'rinishi
    name: str
    path: str               # project root'dan relative
    language: str
    size: int
    updated_at: str


class FileListResponse(BaseModel):
    files: List[FileInfo]


class FileContentResponse(BaseModel):
    id: str
    project_id: str
    path: str
    name: str
    content: str
    language: str
    size: int
    updated_at: str


class FileSavedResponse(BaseModel):
    id: str
    project_id: str
    path: str
    name: str
    size: int
    updated_at: str


# ── Requests ────────────────────────────────────────────────────────────────

class FileWriteRequest(BaseModel):
    content: str = ""


class SuggestRequest(BaseModel):
    file_id: str
    content: str
    cursor_position: int = 0


class SuggestResponse(BaseModel):
    suggestion: Optional[str] = None


class DeleteResponse(BaseModel):
    deleted: bool
    path: str
