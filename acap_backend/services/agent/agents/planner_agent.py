"""Planner Agent — decomposes user task into an agent execution plan."""

from __future__ import annotations

import json
import logging
from typing import Any, AsyncGenerator, Dict, List

from agents.base_agent import BaseAgent
from schemas.agent import AgentType

logger = logging.getLogger(__name__)


class PlannerAgent(BaseAgent):
    agent_type = AgentType.PLANNER
    system_prompt = """You are the Planner Agent for ACAP (AI Coding Agent Platform).

Your job is to analyze the user's request and output a structured JSON execution plan.

Rules:
- Output ONLY valid JSON, no prose, no markdown fences.
- Select only the agents needed (don't over-provision).
- Parallel agents run at the same time; sequential agents run one after another.
- Keep the plan minimal — fewer agents = faster execution.

Available agents:
- planner: (you) — always runs first
- architect: designs structure/architecture for new projects
- coder: writes code
- reviewer: reviews and improves code quality
- tester: writes tests
- debugger: fixes errors and bugs
- devops: Dockerfile, CI/CD, deployment configs
- documentation: README, API docs, comments
- security: OWASP scan, secrets detection
- product: PRD, user stories

Output format (JSON):
{
  "summary": "one-line description of what will be done",
  "parallel_groups": [
    ["agent1", "agent2"],   // agents in this group run simultaneously
    ["agent3"]              // next group runs after group 0 finishes
  ],
  "context_per_agent": {
    "agent_name": "specific instructions for this agent"
  }
}"""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        messages = [
            {
                "role": "user",
                "content": f"Analyze this task and create an execution plan:\n\n{self.task.user_message}",
            }
        ]

        full_response = ""
        async for event in self._stream_completion(messages, max_tokens=1024):
            if event["event"] == "delta":
                full_response += event["data"]["text"]
                yield {"event": "thinking", "data": {"text": event["data"]["text"]}}
            elif event["event"] == "done":
                break

        # Parse plan
        try:
            # Strip possible markdown fences
            clean = full_response.strip()
            if clean.startswith("```"):
                clean = clean.split("```")[1]
                if clean.startswith("json"):
                    clean = clean[4:]
            plan = json.loads(clean.strip())
            yield {"event": "done", "data": {"plan": plan, "content": full_response}}
        except json.JSONDecodeError as e:
            logger.error("Planner JSON parse error: %s\nRaw: %s", e, full_response)
            # Fallback minimal plan
            yield {
                "event": "done",
                "data": {
                    "plan": {
                        "summary": self.task.user_message[:80],
                        "parallel_groups": [["coder"]],
                        "context_per_agent": {"coder": self.task.user_message},
                    },
                    "content": full_response,
                },
            }
