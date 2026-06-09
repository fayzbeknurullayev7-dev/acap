"""Reviewer Agent — reviews code for quality, bugs, and style."""

from __future__ import annotations

from typing import Any, AsyncGenerator, Dict

from agents.base_agent import BaseAgent
from schemas.agent import AgentType


class ReviewerAgent(BaseAgent):
    agent_type = AgentType.REVIEWER
    system_prompt = """You are the Reviewer Agent for ACAP (AI Coding Agent Platform).

You review code produced by the Coder Agent. Your job:
1. Check for bugs, logic errors, edge cases
2. Identify security issues (injections, exposed secrets, etc.)
3. Suggest performance improvements if significant
4. Check code style and readability

Output format:
## Review Summary
Brief overall verdict (APPROVED / NEEDS_CHANGES)

## Issues Found
List each issue with severity (CRITICAL / MAJOR / MINOR) and line reference

## Suggestions
Actionable improvements

## Revised Code (if NEEDS_CHANGES)
Provide corrected code for critical/major issues only."""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        coder_output = getattr(self.task, "_coder_output", "")
        messages = [
            {
                "role": "user",
                "content": (
                    f"Original task:\n{self.task.user_message}\n\n"
                    f"Code to review:\n{coder_output}"
                ),
            }
        ]

        async for event in self._stream_completion(messages, max_tokens=4096):
            yield event
