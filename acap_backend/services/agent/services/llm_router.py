"""
LLM Router — multi-provider streaming with automatic fallback.

Providerlar tartibi (PRIMARY_PROVIDER birinchi qo'yiladi):
    1. Groq    — GROQ_API_KEY bor bo'lsa      (OpenAI-compatible, SSE)
    2. Gemini  — GEMINI_API_KEY bor bo'lsa     (Google v1beta, SSE)
    3. Ollama  — OLLAMA_BASE_URL bor bo'lsa     (NDJSON)

Birorta ham provider sozlanmagan bo'lsa — ValueError.
Bitta provider xato bersa (timeout, 429, 5xx, ulanish xatosi) — keyingisiga avtomatik o'tadi.
Uchalasi ham yiqilsa — {"event": "error"} yield qiladi.

Hech qanday SDK (anthropic/openai/google) ishlatilmaydi — faqat httpx.
"""

from __future__ import annotations

import json
from typing import Any, AsyncGenerator, Dict, List, Optional

import httpx
from loguru import logger

from core.config import settings

# Provider endpointlari
_GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
_GEMINI_URL_TMPL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:streamGenerateContent?alt=sse&key={key}"
)


class LLMRouter:
    """Bir nechta LLM provider ustidan streaming + fallback boshqaruvchi."""

    def __init__(self) -> None:
        self._providers: List[str] = self._build_provider_order()
        if not self._providers:
            raise ValueError(
                "Hech qanday LLM provider sozlanmagan. "
                "GROQ_API_KEY, GEMINI_API_KEY yoki OLLAMA_BASE_URL ni o'rnating."
            )

        # Ulanish uchun qisqa, o'qish uchun uzun timeout (streaming uchun)
        self._timeout = httpx.Timeout(connect=10.0, read=120.0, write=10.0, pool=10.0)
        logger.info("LLMRouter providerlar tartibi: {}", " → ".join(self._providers))

    # ── Provider tartibini qurish ────────────────────────────────────────────

    @staticmethod
    def _build_provider_order() -> List[str]:
        available: List[str] = []
        if settings.GROQ_API_KEY:
            available.append("groq")
        if settings.GEMINI_API_KEY:
            available.append("gemini")
        if settings.OLLAMA_BASE_URL:
            available.append("ollama")

        # PRIMARY_PROVIDER ni boshiga olib chiqamiz (agar mavjud bo'lsa)
        primary = (settings.PRIMARY_PROVIDER or "").strip().lower()
        if primary in available:
            available.remove(primary)
            available.insert(0, primary)
        return available

    # ── Asosiy public metod ──────────────────────────────────────────────────

    async def stream(
        self,
        messages: List[Dict[str, str]],
        system: str = "",
        max_tokens: int = 4096,
        provider: Optional[str] = None,
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Provider(lar)dan streaming javob oladi.

        Yields:
            {"event": "delta", "data": {"text": "..."}}
            {"event": "done",  "data": {"content": "<to'liq matn>", "provider": "<nom>"}}
            {"event": "error", "data": {"error": "..."}}   # barcha providerlar yiqilsa
        """
        # Aniq provider so'ralsa va u mavjud bo'lsa — faqat o'sha; aks holda to'liq tartib
        if provider and provider in self._providers:
            order = [provider]
        else:
            order = list(self._providers)

        last_error: Optional[str] = None

        for name in order:
            full_text = ""
            try:
                async for chunk in self._dispatch(name, messages, system, max_tokens):
                    if chunk:
                        full_text += chunk
                        yield {"event": "delta", "data": {"text": chunk}}

                # Provider muvaffaqiyatli tugadi
                yield {"event": "done", "data": {"content": full_text, "provider": name}}
                return

            except Exception as exc:  # timeout / HTTP xato / ulanish — fallback
                last_error = f"{type(exc).__name__}: {exc}"
                logger.warning(
                    "LLM provider '{}' xato berdi: {} — keyingisiga o'tilyapti", name, last_error
                )
                continue

        logger.error("Barcha LLM providerlar yiqildi. Oxirgi xato: {}", last_error)
        reason = last_error or "unknown error"
        yield {
            "event": "error",
            "data": {"error": f"Barcha LLM providerlar yiqildi: {reason}"},
        }

    # ── Dispatcher ───────────────────────────────────────────────────────────

    def _dispatch(
        self,
        name: str,
        messages: List[Dict[str, str]],
        system: str,
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:
        if name == "groq":
            return self._groq_stream(messages, system, max_tokens)
        if name == "gemini":
            return self._gemini_stream(messages, system, max_tokens)
        if name == "ollama":
            return self._ollama_stream(messages, system, max_tokens)
        raise ValueError(f"Noma'lum provider: {name}")

    # ── Groq (OpenAI-compatible, SSE) ────────────────────────────────────────

    async def _groq_stream(
        self,
        messages: List[Dict[str, str]],
        system: str,
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:
        payload: Dict[str, Any] = {
            "model": settings.GROQ_MODEL,
            "messages": self._with_system(messages, system),
            "max_tokens": max_tokens,
            "stream": True,
        }
        headers = {
            "Authorization": f"Bearer {settings.GROQ_API_KEY}",
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            async with client.stream("POST", _GROQ_URL, json=payload, headers=headers) as resp:
                await self._raise_for_status(resp, "Groq")
                async for line in resp.aiter_lines():
                    if not line or not line.startswith("data:"):
                        continue
                    data = line[len("data:"):].strip()
                    if data == "[DONE]":
                        break
                    try:
                        obj = json.loads(data)
                    except json.JSONDecodeError:
                        continue
                    choices = obj.get("choices") or []
                    if not choices:
                        continue
                    text = (choices[0].get("delta") or {}).get("content")
                    if text:
                        yield text

    # ── Gemini (Google v1beta, SSE) ──────────────────────────────────────────

    async def _gemini_stream(
        self,
        messages: List[Dict[str, str]],
        system: str,
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:
        contents: List[Dict[str, Any]] = []
        for m in messages:
            role = "model" if m.get("role") == "assistant" else "user"
            contents.append({"role": role, "parts": [{"text": m.get("content", "")}]})

        payload: Dict[str, Any] = {
            "contents": contents,
            "generationConfig": {"maxOutputTokens": max_tokens},
        }
        if system:
            payload["systemInstruction"] = {"parts": [{"text": system}]}

        url = _GEMINI_URL_TMPL.format(model=settings.GEMINI_MODEL, key=settings.GEMINI_API_KEY)

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            async with client.stream(
                "POST", url, json=payload, headers={"Content-Type": "application/json"}
            ) as resp:
                await self._raise_for_status(resp, "Gemini")
                async for line in resp.aiter_lines():
                    if not line or not line.startswith("data:"):
                        continue
                    data = line[len("data:"):].strip()
                    if not data:
                        continue
                    try:
                        obj = json.loads(data)
                    except json.JSONDecodeError:
                        continue
                    for cand in obj.get("candidates", []):
                        for part in (cand.get("content") or {}).get("parts", []):
                            text = part.get("text")
                            if text:
                                yield text

    # ── Ollama (NDJSON) ──────────────────────────────────────────────────────

    async def _ollama_stream(
        self,
        messages: List[Dict[str, str]],
        system: str,
        max_tokens: int,
    ) -> AsyncGenerator[str, None]:
        payload: Dict[str, Any] = {
            "model": settings.OLLAMA_MODEL,
            "messages": self._with_system(messages, system),
            "stream": True,
            "options": {"num_predict": max_tokens},
        }
        url = settings.OLLAMA_BASE_URL.rstrip("/") + "/api/chat"

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            async with client.stream("POST", url, json=payload) as resp:
                await self._raise_for_status(resp, "Ollama")
                async for line in resp.aiter_lines():
                    if not line.strip():
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    text = (obj.get("message") or {}).get("content")
                    if text:
                        yield text
                    if obj.get("done"):
                        break

    # ── Helpers ──────────────────────────────────────────────────────────────

    @staticmethod
    def _with_system(
        messages: List[Dict[str, str]], system: str
    ) -> List[Dict[str, str]]:
        """OpenAI/Ollama uchun system xabarini messages boshiga qo'yadi."""
        if system:
            return [{"role": "system", "content": system}, *messages]
        return list(messages)

    @staticmethod
    async def _raise_for_status(resp: httpx.Response, provider: str) -> None:
        """Streaming javobda status kodini tekshiradi (4xx/5xx → xato → fallback)."""
        if resp.status_code >= 400:
            body = (await resp.aread()).decode("utf-8", errors="replace")
            raise RuntimeError(f"{provider} HTTP {resp.status_code}: {body[:300]}")
