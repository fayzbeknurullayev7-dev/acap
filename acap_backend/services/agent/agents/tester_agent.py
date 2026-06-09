"""Tester Agent — generates unit and integration tests."""

from __future__ import annotations

from typing import Any, AsyncGenerator, Dict

from agents.base_agent import BaseAgent
from schemas.agent import AgentType


class TesterAgent(BaseAgent):
    agent_type = AgentType.TESTER
    system_prompt = """You are the Tester Agent for ACAP.

Generate comprehensive tests for the provided code:
- Unit tests for all public functions/methods
- Edge cases and error paths
- Integration tests where appropriate
- Use the project's testing framework (pytest, jest, flutter_test, etc.)

Format each test file with // filename: header."""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        coder_output = getattr(self.task, "_coder_output", "")
        messages = [
            {
                "role": "user",
                "content": (
                    f"Task: {self.task.user_message}\n\n"
                    f"Code to test:\n{coder_output}\n\n"
                    "Write comprehensive tests."
                ),
            }
        ]
        async for event in self._stream_completion(messages, max_tokens=4096):
            yield event
