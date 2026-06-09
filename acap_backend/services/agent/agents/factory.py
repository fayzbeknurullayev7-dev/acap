"""Agent factory — maps AgentType → agent class."""

from typing import Dict, Type

from agents.base_agent import BaseAgent
from agents.planner_agent import PlannerAgent
from agents.coder_agent import CoderAgent
from agents.reviewer_agent import ReviewerAgent
from agents.tester_agent import TesterAgent
from agents.debugger_agent import DebuggerAgent
from agents.specialized_agents import (
    ArchitectAgent,
    DevOpsAgent,
    DocumentationAgent,
    SecurityAgent,
    ProductAgent,
)
from schemas.agent import AgentType

_REGISTRY: Dict[AgentType, Type[BaseAgent]] = {
    AgentType.PLANNER:       PlannerAgent,
    AgentType.ARCHITECT:     ArchitectAgent,
    AgentType.CODER:         CoderAgent,
    AgentType.REVIEWER:      ReviewerAgent,
    AgentType.TESTER:        TesterAgent,
    AgentType.DEBUGGER:      DebuggerAgent,
    AgentType.DEVOPS:        DevOpsAgent,
    AgentType.DOCUMENTATION: DocumentationAgent,
    AgentType.SECURITY:      SecurityAgent,
    AgentType.PRODUCT:       ProductAgent,
}


def get_agent(agent_type: AgentType, task) -> BaseAgent:
    cls = _REGISTRY.get(agent_type)
    if cls is None:
        raise ValueError(f"Unknown agent type: {agent_type}")
    return cls(task)
