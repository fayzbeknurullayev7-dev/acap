# filename: acap_backend/services/files/services/file_service.py
"""
Files service — DATABASE ISHLATMAYDI.

Barcha fayllar /workspaces/{project_id}/ da disk'da saqlanadi.
Metadata (nom, yo'l, o'lcham, oxirgi o'zgartirish) os/pathlib orqali
real vaqtda o'qiladi.
"""

import base64
import os
import re
from datetime import datetime, timezone
from typing import List

import httpx
from fastapi import HTTPException, status
from loguru import logger

from core.config import settings
from schemas.file import FileContentResponse, FileInfo, FileSavedResponse

# ── Language detection ──────────────────────────────────────────────────────

_EXT_LANGUAGE = {
    ".dart": "dart",
    ".py": "python",
    ".js": "javascript",
    ".ts": "typescript",
    ".kt": "kotlin",
    ".java": "java",
    ".rs": "rust",
    ".go": "go",
    ".cpp": "cpp",
    ".cc": "cpp",
    ".html": "html",
    ".css": "css",
    ".json": "json",
    ".yaml": "yaml",
    ".yml": "yaml",
    ".md": "markdown",
    ".sh": "bash",
    ".sql": "sql",
}

_PROJECT_ID_RE = re.compile(r"^[A-Za-z0-9-]+$")


def detect_language(filename: str) -> str:
    _, ext = os.path.splitext(filename.lower())
    return _EXT_LANGUAGE.get(ext, "plaintext")


# ── Path safety ─────────────────────────────────────────────────────────────

def validate_project_id(project_id: str) -> None:
    """Faqat alphanumeric + hyphen (-) ruxsat etiladi."""
    if not _PROJECT_ID_RE.match(project_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid project_id",
        )


def _project_root(project_id: str) -> str:
    return os.path.realpath(os.path.join(settings.WORKSPACES_ROOT, project_id))


def safe_join(project_id: str, file_path: str) -> str:
    """
    Path traversal himoyasi.
    base = realpath(/workspaces/{project_id})
    target = realpath(join(base, file_path))
    target base ichida bo'lmasa → 403
    """
    validate_project_id(project_id)
    base = _project_root(project_id)
    target = os.path.realpath(os.path.join(base, file_path))
    if target != base and not target.startswith(base + os.sep):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Path traversal detected",
        )
    return target


def _encode_id(rel_path: str) -> str:
    return base64.urlsafe_b64encode(rel_path.encode()).decode()


def _iso_mtime(path: str) -> str:
    ts = os.path.getmtime(path)
    return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()


# ── Operations ──────────────────────────────────────────────────────────────

class FileService:
    """Disk-backed file operations for a single project workspace."""

    def list_files(self, project_id: str) -> List[FileInfo]:
        validate_project_id(project_id)
        base = _project_root(project_id)
        if not os.path.isdir(base):
            return []

        files: List[FileInfo] = []
        for root, dirs, filenames in os.walk(base):
            # Hidden papkalarni o'tkazib yuboramiz (.git, .cache, ...)
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for fname in filenames:
                if fname.startswith("."):
                    continue
                abs_path = os.path.join(root, fname)
                rel_path = os.path.relpath(abs_path, base)
                try:
                    size = os.path.getsize(abs_path)
                    updated = _iso_mtime(abs_path)
                except OSError:
                    continue
                files.append(
                    FileInfo(
                        id=_encode_id(rel_path),
                        name=fname,
                        path=rel_path,
                        language=detect_language(fname),
                        size=size,
                        updated_at=updated,
                    )
                )
        files.sort(key=lambda f: f.path)
        return files

    def read_file(self, project_id: str, file_path: str) -> FileContentResponse:
        target = safe_join(project_id, file_path)
        if not os.path.isfile(target):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File not found",
            )

        size = os.path.getsize(target)
        if size > settings.MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File too large (max {settings.MAX_FILE_SIZE} bytes)",
            )

        with open(target, "r", encoding="utf-8", errors="replace") as fh:
            content = fh.read()

        base = _project_root(project_id)
        rel_path = os.path.relpath(target, base)
        name = os.path.basename(target)
        return FileContentResponse(
            id=_encode_id(rel_path),
            project_id=project_id,
            path=rel_path,
            name=name,
            content=content,
            language=detect_language(name),
            size=size,
            updated_at=_iso_mtime(target),
        )

    def write_file(
        self, project_id: str, file_path: str, content: str
    ) -> FileSavedResponse:
        target = safe_join(project_id, file_path)
        # mkdir -p
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "w", encoding="utf-8") as fh:
            fh.write(content)

        base = _project_root(project_id)
        rel_path = os.path.relpath(target, base)
        name = os.path.basename(target)
        logger.info("File saved: {}/{}", project_id, rel_path)
        return FileSavedResponse(
            id=_encode_id(rel_path),
            project_id=project_id,
            path=rel_path,
            name=name,
            size=os.path.getsize(target),
            updated_at=_iso_mtime(target),
        )

    def delete_file(self, project_id: str, file_path: str) -> str:
        target = safe_join(project_id, file_path)
        if not os.path.isfile(target):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File not found",
            )
        base = _project_root(project_id)
        rel_path = os.path.relpath(target, base)
        os.remove(target)
        logger.info("File deleted: {}/{}", project_id, rel_path)
        return rel_path

    # ── LLM code completion (GROQ) ───────────────────────────────
    async def suggest(self, content: str, cursor_position: int) -> str | None:
        if not settings.GROQ_API_KEY:
            logger.warning("GROQ_API_KEY not set — suggestion skipped")
            return None

        prompt = (
            f"Complete the following code at cursor position {cursor_position}:\n"
            f"{content[-500:]}\n"
            f"Continue from here:"
        )
        payload = {
            "model": settings.GROQ_MODEL,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a code completion engine. "
                        "Return ONLY the code continuation, no explanations."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.2,
            "max_tokens": 128,
        }
        headers = {"Authorization": f"Bearer {settings.GROQ_API_KEY}"}

        try:
            async with httpx.AsyncClient(timeout=20.0) as client:
                resp = await client.post(
                    f"{settings.GROQ_BASE_URL}/chat/completions",
                    json=payload,
                    headers=headers,
                )
                resp.raise_for_status()
                data = resp.json()
                return data["choices"][0]["message"]["content"]
        except Exception as exc:  # noqa: BLE001 — xato bo'lsa null qaytaramiz
            logger.error("GROQ suggestion failed: {}", exc)
            return None
