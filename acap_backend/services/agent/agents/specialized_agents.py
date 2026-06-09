"""DevOps, Documentation, Security, Architect, and Product agents."""

from __future__ import annotations

from typing import Any, AsyncGenerator, Dict

from agents.base_agent import BaseAgent
from schemas.agent import AgentType


class ArchitectAgent(BaseAgent):
    agent_type = AgentType.ARCHITECT
    system_prompt = """You are the Architect Agent for ACAP.
Design system architecture, folder structure, and tech stack for the project.
Provide:
- High-level architecture diagram (ASCII or description)
- Folder structure
- Technology choices with rationale
- Key interfaces and contracts between components"""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        messages = [{"role": "user", "content": self.task.user_message}]
        async for event in self._stream_completion(messages, max_tokens=4096):
            yield event


class DevOpsAgent(BaseAgent):
    agent_type = AgentType.DEVOPS
    system_prompt = """You are the DevOps Agent for ACAP.
Create CI/CD pipelines, Dockerfiles, Kubernetes manifests, and deployment configs.
Output each file with // filename: or # filename: headers."""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        messages = [{"role": "user", "content": self.task.user_message}]
        async for event in self._stream_completion(messages, max_tokens=4096):
            yield event


class DocumentationAgent(BaseAgent):
    agent_type = AgentType.DOCUMENTATION
    system_prompt = """You are the Documentation Agent for ACAP.
Generate clear README files, API documentation, and inline code comments.
Use proper markdown formatting for README files."""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        coder_output = getattr(self.task, "_coder_output", "")
        messages = [
            {
                "role": "user",
                "content": (
                    f"Task: {self.task.user_message}\n\n"
                    f"Code:\n{coder_output}\n\n"
                    "Generate documentation."
                ),
            }
        ]
        async for event in self._stream_completion(messages, max_tokens=4096):
            yield event


class SecurityAgent(BaseAgent):
    agent_type = AgentType.SECURITY
    system_prompt = """You are the Security Agent for ACAP.
Scan code for security vulnerabilities:
- OWASP Top 10
- Exposed secrets or credentials
- Injection vulnerabilities
- Insecure dependencies
- Authentication/authorization flaws

Output a security report with severity ratings and remediation steps."""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        coder_output = getattr(self.task, "_coder_output", "")
        messages = [
            {
                "role": "user",
                "content": (
                    f"Code to audit:\n{coder_output}\n\n"
                    "Perform a security audit."
                ),
            }
        ]
        async for event in self._stream_completion(messages, max_tokens=2048):
            yield event


class ProductAgent(BaseAgent):
    agent_type = AgentType.PRODUCT
    system_prompt = """You are the Product Agent for ACAP.
Create PRDs, user stories, acceptance criteria, and feature specifications.
Use clear, structured markdown output."""

    async def run(self) -> AsyncGenerator[Dict[str, Any], None]:
        messages = [{"role": "user", "content": self.task.user_message}]
        async for event in self._stream_completion(messages, max_tokens=4096):
            yield event
