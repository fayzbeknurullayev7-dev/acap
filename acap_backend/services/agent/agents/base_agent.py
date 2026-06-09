"""Base class for all ACAP agents.

LLM provayderi: LLMRouter (Groq → Gemini → Ollama, avtomatik fallback).
ANTHROPIC ISHLATILMAYDI.

Tool-calling: Groq/Ollama doimiy ravishda native tool_use ni qo'llab-quvvatlamagani
uchun, agentlar tool'larni matn ichidagi <tool_call>...</tool_call> bloklari orqali
chaqiradi. BaseAgent bu bloklarni parse qilib, tools.call_tool() ni ishga tushiradi
va natijani modelga qaytaradi (max MAX_TOOL_ITERATIONS iteratsiya).
"""

from __future__ import annotations

import json
import logging
import re
from abc import ABC, abstractmethod
from typing import Any, AsyncGenerator, Dict, List, Optional

from core.config import settings
from models.task import Task
from schemas.agent import AgentType
from services.llm_router import LLMRouter
from tools import call_tool

logger = logging.getLogger(__name__)

# <tool_call> { ... } </tool_call> bloklarini topish uchun
_TOOL_CALL_RE = re.compile(r"<tool_call>\s*(.*?)\s*</tool_call>", re.DOTALL)

# Tool'lardan foydalanadigan agentlar uchun system prompt qo'shimchasi
_TOOLS_INSTRUCTIONS = """

You have access to the project filesystem through tools. To call a tool, emit a block:

<tool_call>
{"name": "<tool_name>", "args": { ... }}
</tool_call>

Available tools (project_id is injected automatically — do NOT include it):
- read_file(path)                      — read a file (max 50KB)
- write_file(path, content)            — create/overwrite a file
- list_directory(path)                 — tree listing (path "." for project root)
- run_command(command, timeout=30)     — run a shell command in the project dir
- search_files(pattern)                — recursive glob, e.g. "*.py"

Rules:
- Emit one or more <tool_call> blocks when you need to act on the filesystem.
- After each tool call you will receive a <tool_result> with the output; continue from there.
- When the task is fully complete, reply WITHOUT any <tool_call> block — that final text is your answer.
"""


class BaseAgent(ABC):
    """Every agent extends this class."""

    agent_type: AgentType
    system_prompt: str = ""

    def __init__(self, task: Task):
        self.task = task
        self.llm = LLMRouter()
        self.log = logging.getLogger(f"agent.{self.agent_type.value}")

    # ── Public interface ──────────────────────────────────────────────────

    @abstractmethod
    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Yield event dicts consumed by the orchestrator.
        Expected keys: {'event': str, 'data': dict}

        event types:
          'thinking'    — intermediate thought (not shown to user directly)
          'delta'       — streamed output token
          'tool_call'   — agent is calling a tool
          'tool_result' — tool returned
          'done'        — final output ready
          'error'       — agent failed
        """
        ...

    # ── Plain text streaming (tool'siz agentlar uchun) ────────────────────

    async def _stream_completion(
        self,
        messages: List[Dict[str, str]],
        tools: Optional[List[Dict]] = None,  # signature mosligi uchun; e'tiborga olinmaydi
        max_tokens: int = 4096,
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        LLMRouter orqali oddiy matn streaming.
        Yields: {"event": "delta", ...}, {"event": "done", ...}, {"event": "error", ...}
        """
        async for event in self.llm.stream(
            messages, system=self.system_prompt, max_tokens=max_tokens
        ):
            yield event

    # ── Tool-loop streaming (fayl tizimi bilan ishlaydigan agentlar uchun) ─

    async def _run_with_tools(
        self,
        messages: List[Dict[str, str]],
        max_tokens: int = 4096,
        max_iterations: Optional[int] = None,
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Agentic loop: model <tool_call> chiqarsa — tool ishga tushadi,
        natija modelga qaytariladi, jarayon tool yo'q javobgacha davom etadi.

        Yields: delta / tool_call / tool_result / done / error eventlar.
        """
        max_iterations = max_iterations or settings.MAX_TOOL_ITERATIONS
        project_id = self.task.project_id
        system = self.system_prompt + _TOOLS_INSTRUCTIONS

        conversation: List[Dict[str, str]] = list(messages)
        assistant_text = ""

        for iteration in range(max_iterations):
            assistant_text = ""

            # 1) Bitta to'liq completion'ni stream qilamiz
            async for event in self.llm.stream(
                conversation, system=system, max_tokens=max_tokens
            ):
                etype = event["event"]
                if etype == "delta":
                    assistant_text += event["data"].get("text", "")
                    yield event
                elif etype == "done":
                    # Router'ning to'liq matni — eng ishonchli manba
                    assistant_text = event["data"].get("content", assistant_text)
                elif etype == "error":
                    yield event
                    return

            # 2) Tool chaqiruvlarini ajratamiz
            tool_calls = self._parse_tool_calls(assistant_text)
            if not tool_calls:
                # Tool yo'q — bu yakuniy javob
                yield {"event": "done", "data": {"content": assistant_text}}
                return

            # 3) Assistant navbatini suhbatga qo'shamiz
            conversation.append({"role": "assistant", "content": assistant_text})

            # 4) Har bir tool'ni ishga tushiramiz
            result_blocks: List[str] = []
            for tc in tool_calls:
                name = tc["name"]
                args = dict(tc.get("args") or {})
                # project_id ni MAJBURIY o'zimiz beramiz (LLM tanlay olmaydi — xavfsizlik)
                args["project_id"] = project_id

                yield {
                    "event": "tool_call",
                    "data": {"name": name, "arguments": args, "is_running": True},
                }

                result = await call_tool(name, args)

                yield {
                    "event": "tool_result",
                    "data": {"name": name, "result": result[:2000]},
                }
                result_blocks.append(
                    f'<tool_result name="{name}">\n{result}\n</tool_result>'
                )

            # 5) Tool natijalarini model uchun user navbati sifatida qaytaramiz
            conversation.append(
                {
                    "role": "user",
                    "content": (
                        "\n".join(result_blocks)
                        + "\n\nContinue. When finished, reply WITHOUT any <tool_call> block."
                    ),
                }
            )

        # Iteratsiya limiti tugadi — oxirgi matnni yakuniy deb qaytaramiz
        logger.warning(
            "Agent %s reached max tool iterations (%d)",
            self.agent_type.value,
            max_iterations,
        )
        yield {"event": "done", "data": {"content": assistant_text}}

    # ── Tool-call parser ──────────────────────────────────────────────────

    def _parse_tool_calls(self, text: str) -> List[Dict[str, Any]]:
        """
        Matndan <tool_call>{json}</tool_call> bloklarini ajratadi.
        Har bir blok {"name": str, "args": dict} bo'lishi kerak.
        Yaroqsiz bloklar e'tiborga olinmaydi (warning log bilan).
        """
        calls: List[Dict[str, Any]] = []
        for match in _TOOL_CALL_RE.finditer(text):
            block = match.group(1).strip()
            try:
                obj = json.loads(block)
            except json.JSONDecodeError:
                self.log.warning("Tool_call blokini parse qilib bo'lmadi: %s", block[:200])
                continue
            if isinstance(obj, dict) and isinstance(obj.get("name"), str):
                calls.append({"name": obj["name"], "args": obj.get("args", {})})
            else:
                self.log.warning("Tool_call blokida 'name' yo'q: %s", block[:200])
        return calls
