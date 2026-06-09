"""Debugger Agent — analyzes errors and produces fixes."""

from __future__ import annotations

from typing import Any, AsyncGenerator, Dict

from agents.base_agent import BaseAgent
from schemas.agent import AgentType


class DebuggerAgent(BaseAgent):
    agent_type = AgentType.DEBUGGER
    system_prompt = """You are the Debugger Agent for ACAP.

Analyze the error or bug report, identify the root cause, and provide a fix.

You may use the tools (read_file, list_directory, search_files, run_command) to
inspect the project and reproduce the issue, and write_file to apply the fix.

When done, output:
## Root Cause Analysis
What went wrong and why.

## Fix
What you changed (and which files).

## Prevention
How to avoid this class of bug in future."""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        messages = [{"role": "user", "content": self.task.user_message}]
        async for event in self._run_with_tools(messages, max_tokens=4096):
            yield event
