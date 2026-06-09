"""Coder Agent — writes production-quality code."""

from __future__ import annotations

from typing import Any, AsyncGenerator, Dict

from agents.base_agent import BaseAgent
from schemas.agent import AgentType


class CoderAgent(BaseAgent):
    agent_type = AgentType.CODER
    system_prompt = """You are the Coder Agent for ACAP (AI Coding Agent Platform).

You write clean, production-quality code based on the task description and any architecture context provided.

Guidelines:
- Write complete, working code (no placeholders like "// TODO" unless genuinely deferred)
- Follow the project's language/framework conventions
- Include error handling
- Add brief inline comments for non-obvious logic
- Use the write_file tool to persist each file into the project workspace
- Use read_file / list_directory first if you need to understand existing code

When done, give a short summary of the files you created and why."""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        context = getattr(self.task, "_agent_context", {}).get("coder", "")
        messages = [
            {
                "role": "user",
                "content": (
                    f"Project context:\n{context}\n\n"
                    f"Task:\n{self.task.user_message}\n\n"
                    "Write the required code and save it with the write_file tool."
                ),
            }
        ]

        async for event in self._run_with_tools(messages, max_tokens=8192):
            yield event
