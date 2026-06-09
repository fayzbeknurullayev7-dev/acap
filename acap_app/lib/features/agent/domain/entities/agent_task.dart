// lib/features/agent/domain/entities/agent_task.dart

enum AgentType {
  planner,
  architect,
  coder,
  reviewer,
  tester,
  debugger,
  devops,
  documentation,
  security,
  product,
}

enum AgentStatus { idle, running, waiting, done, error, skipped }

enum TaskStatus { queued, planning, running, reviewing, done, error, cancelled }

extension AgentTypeX on AgentType {
  String get label {
    switch (this) {
      case AgentType.planner:       return 'Planner';
      case AgentType.architect:     return 'Architect';
      case AgentType.coder:         return 'Coder';
      case AgentType.reviewer:      return 'Reviewer';
      case AgentType.tester:        return 'Tester';
      case AgentType.debugger:      return 'Debugger';
      case AgentType.devops:        return 'DevOps';
      case AgentType.documentation: return 'Docs';
      case AgentType.security:      return 'Security';
      case AgentType.product:       return 'Product';
    }
  }

  String get emoji {
    switch (this) {
      case AgentType.planner:       return '🧠';
      case AgentType.architect:     return '🏗️';
      case AgentType.coder:         return '💻';
      case AgentType.reviewer:      return '🔍';
      case AgentType.tester:        return '🧪';
      case AgentType.debugger:      return '🐛';
      case AgentType.devops:        return '🚀';
      case AgentType.documentation: return '📖';
      case AgentType.security:      return '🔒';
      case AgentType.product:       return '📋';
    }
  }
}

class AgentStep {
  final AgentType agent;
  final AgentStatus status;
  final String message;
  final String? output;
  final List<ToolCallInfo> toolCalls;

  const AgentStep({
    required this.agent,
    required this.status,
    this.message = '',
    this.output,
    this.toolCalls = const [],
  });

  AgentStep copyWith({
    AgentStatus? status,
    String? message,
    String? output,
    List<ToolCallInfo>? toolCalls,
  }) {
    return AgentStep(
      agent:     agent,
      status:    status    ?? this.status,
      message:   message   ?? this.message,
      output:    output    ?? this.output,
      toolCalls: toolCalls ?? this.toolCalls,
    );
  }
}

class ToolCallInfo {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  final String? result;
  final bool isRunning;

  const ToolCallInfo({
    required this.id,
    required this.name,
    required this.arguments,
    this.result,
    this.isRunning = false,
  });
}

class AgentTask {
  final String taskId;
  final String projectId;
  final String sessionId;
  final String userMessage;
  final TaskStatus status;
  final List<AgentStep> steps;
  final String? finalOutput;
  final String? error;
  final DateTime createdAt;

  const AgentTask({
    required this.taskId,
    required this.projectId,
    required this.sessionId,
    required this.userMessage,
    required this.status,
    required this.steps,
    required this.createdAt,
    this.finalOutput,
    this.error,
  });

  bool get isActive =>
      status == TaskStatus.queued ||
      status == TaskStatus.planning ||
      status == TaskStatus.running ||
      status == TaskStatus.reviewing;

  bool get isDone     => status == TaskStatus.done;
  bool get hasError   => status == TaskStatus.error;
  bool get isCancelled => status == TaskStatus.cancelled;

  AgentTask copyWith({
    TaskStatus? status,
    List<AgentStep>? steps,
    String? finalOutput,
    String? error,
  }) {
    return AgentTask(
      taskId:      taskId,
      projectId:   projectId,
      sessionId:   sessionId,
      userMessage: userMessage,
      status:      status      ?? this.status,
      steps:       steps       ?? this.steps,
      finalOutput: finalOutput ?? this.finalOutput,
      error:       error       ?? this.error,
      createdAt:   createdAt,
    );
  }
}
