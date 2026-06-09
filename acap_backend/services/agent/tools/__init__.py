"""
Agent Tools — fayl tizimi va shell ustida xavfsiz amallar.

Barcha amallar /workspaces/{project_id}/ ichida bajariladi.
Har bir tool path traversal'dan himoyalangan (os.path.realpath bilan tekshiriladi).

Tool chaqirish:
    result = await call_tool("write_file", {"path": "main.py", "content": "...", "project_id": "p1"})
"""

from __future__ import annotations

import asyncio
import glob
import os
import re
from typing import Awaitable, Callable, Dict

from loguru import logger

# ── Konstantalar ─────────────────────────────────────────────────────────────

_WORKSPACES_ROOT = "/workspaces"
_MAX_READ_BYTES = 50 * 1024          # 50 KB
_MAX_SEARCH_RESULTS = 50
_MAX_TREE_DEPTH = 3
_DEFAULT_CMD_TIMEOUT = 30

# Bloklangan buyruq naqshlari (run_command uchun)
_BLOCKED_PATTERNS = [
    re.compile(r"rm\s+-rf\s+/"),                    # rm -rf /
    re.compile(r"\bsudo\b"),                         # sudo
    re.compile(r":\s*\(\s*\)\s*\{"),                 # :(){ :|:& } — fork bomb
    re.compile(r"(curl|wget)\b[^\n|]*\|\s*(ba)?sh"),  # curl|bash, wget|bash
    re.compile(r"\bmkfs\b"),                         # disk formatlash
    re.compile(r"\bdd\s+if="),                       # dd if=...
    re.compile(r">\s*/dev/sd"),                       # diskka to'g'ridan yozish
]


# ── Path xavfsizligi ─────────────────────────────────────────────────────────

def _resolve(path: str, project_id: str) -> tuple[str, str]:
    """
    /workspaces/{project_id}/{path} ni xavfsiz hal qiladi.

    Returns:
        (base_dir, target_path) — ikkalasi ham absolute, normalized.

    Raises:
        ValueError — project_id yoki path workspace'dan tashqariga chiqsa.
    """
    root = os.path.realpath(_WORKSPACES_ROOT)

    # project_id workspace ildizidan tashqariga chiqmasligi kerak
    base = os.path.realpath(os.path.join(root, project_id))
    if base != root and not base.startswith(root + os.sep):
        raise ValueError("noto'g'ri project_id")

    # path base ichida qolishi kerak
    target = os.path.realpath(os.path.join(base, path))
    if target != base and not target.startswith(base + os.sep):
        raise ValueError("path traversal aniqlandi")

    return base, target


def _is_blocked(command: str) -> bool:
    return any(p.search(command) for p in _BLOCKED_PATTERNS)


# ── 1. read_file ─────────────────────────────────────────────────────────────

async def read_file(path: str, project_id: str) -> str:
    """Faylni o'qiydi (max 50KB, kattaroq bo'lsa truncate qilinadi)."""
    try:
        _, target = _resolve(path, project_id)
    except ValueError as e:
        return f"Error: {e}"

    if not os.path.isfile(target):
        return f"Error: fayl topilmadi: {path}"

    def _read() -> str:
        with open(target, "rb") as f:
            data = f.read(_MAX_READ_BYTES + 1)
        truncated = len(data) > _MAX_READ_BYTES
        text = data[:_MAX_READ_BYTES].decode("utf-8", errors="replace")
        if truncated:
            text += f"\n\n[... {_MAX_READ_BYTES} baytda kesildi ...]"
        return text

    return await asyncio.to_thread(_read)


# ── 2. write_file ────────────────────────────────────────────────────────────

async def write_file(path: str, content: str, project_id: str) -> str:
    """Faylga yozadi (kerakli papkalarni yaratadi). Yozilgan bayt sonini qaytaradi."""
    try:
        _, target = _resolve(path, project_id)
    except ValueError as e:
        return f"Error: {e}"

    def _write() -> int:
        parent = os.path.dirname(target)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(target, "w", encoding="utf-8") as f:
            return f.write(content)

    try:
        written = await asyncio.to_thread(_write)
    except OSError as e:
        return f"Error: yozib bo'lmadi: {e}"
    return f"OK: {path} ga {written} bayt yozildi"


# ── 3. list_directory ────────────────────────────────────────────────────────

async def list_directory(path: str, project_id: str) -> str:
    """Papkani tree ko'rinishida qaytaradi (max depth=3, yashirin fayllar o'tkaziladi)."""
    try:
        _, target = _resolve(path, project_id)
    except ValueError as e:
        return f"Error: {e}"

    if not os.path.isdir(target):
        return f"Error: papka topilmadi: {path}"

    def _tree() -> str:
        lines: list[str] = []

        def walk(directory: str, prefix: str, depth: int) -> None:
            if depth > _MAX_TREE_DEPTH:
                return
            try:
                entries = sorted(e for e in os.listdir(directory) if not e.startswith("."))
            except OSError:
                return
            for idx, name in enumerate(entries):
                full = os.path.join(directory, name)
                is_last = idx == len(entries) - 1
                connector = "└── " if is_last else "├── "
                is_dir = os.path.isdir(full)
                lines.append(f"{prefix}{connector}{name}{'/' if is_dir else ''}")
                if is_dir:
                    extension = "    " if is_last else "│   "
                    walk(full, prefix + extension, depth + 1)

        root_label = os.path.basename(target.rstrip("/")) or "/"
        lines.append(f"{root_label}/")
        walk(target, "", 1)
        return "\n".join(lines)

    return await asyncio.to_thread(_tree)


# ── 4. run_command ───────────────────────────────────────────────────────────

async def run_command(
    command: str,
    project_id: str,
    timeout: int = _DEFAULT_CMD_TIMEOUT,
) -> str:
    """Shell buyrug'ini /workspaces/{project_id}/ ichida ishga tushiradi (stdout+stderr)."""
    try:
        base, _ = _resolve(".", project_id)
    except ValueError as e:
        return f"Error: {e}"

    if _is_blocked(command):
        return "Error: buyruq xavfsizlik siyosati bilan bloklangan"

    os.makedirs(base, exist_ok=True)

    try:
        proc = await asyncio.create_subprocess_shell(
            command,
            cwd=base,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
    except Exception as e:  # noqa: BLE001 — subprocess ochilmasligi mumkin
        return f"Error: jarayon ishga tushmadi: {e}"

    try:
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=timeout)
    except asyncio.TimeoutError:
        proc.kill()
        try:
            await proc.wait()
        except ProcessLookupError:
            pass
        return f"Command timed out ({timeout}s)"

    output = (stdout or b"").decode("utf-8", errors="replace")
    if output.strip():
        return output
    return f"(exit code {proc.returncode}, chiqish yo'q)"


# ── 5. search_files ──────────────────────────────────────────────────────────

async def search_files(pattern: str, project_id: str) -> str:
    """Rekursiv glob bilan fayl qidiradi (max 50 natija)."""
    try:
        base, _ = _resolve(".", project_id)
    except ValueError as e:
        return f"Error: {e}"

    def _search() -> str:
        matches = glob.glob(os.path.join(base, "**", pattern), recursive=True)
        rels = [os.path.relpath(m, base) for m in matches][:_MAX_SEARCH_RESULTS]
        return "\n".join(rels) if rels else "Mos fayl topilmadi"

    return await asyncio.to_thread(_search)


# ── Registry + dispatcher ────────────────────────────────────────────────────

TOOL_REGISTRY: Dict[str, Callable[..., Awaitable[str]]] = {
    "read_file": read_file,
    "write_file": write_file,
    "list_directory": list_directory,
    "run_command": run_command,
    "search_files": search_files,
}


async def call_tool(name: str, args: dict) -> str:
    """
    Nom va argumentlar bo'yicha tool'ni chaqiradi.
    Xato yoki noma'lum tool bo'lsa — "Tool error: ..." qaytaradi (hech qachon exception otmaydi).
    """
    fn = TOOL_REGISTRY.get(name)
    if fn is None:
        return f"Tool error: noma'lum tool '{name}'"
    try:
        return await fn(**(args or {}))
    except TypeError as e:
        return f"Tool error: '{name}' uchun noto'g'ri argumentlar: {e}"
    except Exception as e:  # noqa: BLE001 — tool xatosi LLM'ga matn sifatida qaytadi
        logger.exception("Tool '{}' xato berdi", name)
        return f"Tool error: {e}"
