// lib/features/agent/presentation/providers/agent_provider.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/agent_remote_datasource.dart';
import '../../data/models/agent_event.dart';
import '../../domain/entities/agent_task.dart';

// ── Infrastructure ─────────────────────────────────────────────────────────

final agentDatasourceProvider = Provider<AgentRemoteDatasource>(
  (_) => AgentRemoteDatasourceImpl(),
);

// ── State ──────────────────────────────────────────────────────────────────

class AgentState {
  final AgentTask? task;
  final bool isSubmitting;
  final String? streamingDelta; // accumulated delta for active agent
  final String? error;

  const AgentState({
    this.task,
    this.isSubmitting = false,
    this.streamingDelta,
    this.error,
  });

  bool get hasTask  => task != null;
  bool get isActive => task?.isActive ?? false;

  AgentState copyWith({
    AgentTask? task,
    bool? isSubmitting,
    String? streamingDelta,
    String? error,
    bool clearStreamingDelta = false,
    bool clearError = false,
  }) {
    return AgentState(
      task:            task           ?? this.task,
      isSubmitting:    isSubmitting   ?? this.isSubmitting,
      streamingDelta:  clearStreamingDelta ? null : (streamingDelta ?? this.streamingDelta),
      error:           clearError     ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class AgentNotifier extends StateNotifier<AgentState> {
  final AgentRemoteDatasource _datasource;
  StreamSubscription<AgentEventModel>? _streamSub;

  AgentNotifier(this._datasource) : super(const AgentState());

  // ── Submit task ─────────────────────────────────────────────────────────

  Future<void> submitTask({
    required String projectId,
    required String sessionId,
    required String userMessage,
    List<String>? selectedAgents,
  }) async {
    if (state.isActive || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final taskId = await _datasource.submitTask(
        projectId:      projectId,
        sessionId:      sessionId,
        userMessage:    userMessage,
        selectedAgents: selectedAgents,
      );

      // Create initial task state
      final task = AgentTask(
        taskId:      taskId,
        projectId:   projectId,
        sessionId:   sessionId,
        userMessage: userMessage,
        status:      TaskStatus.queued,
        steps:       const [],
        createdAt:   DateTime.now(),
      );

      state = state.copyWith(task: task, isSubmitting: false);

      // Start streaming
      _subscribeToStream(taskId);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  // ── Cancel task ─────────────────────────────────────────────────────────

  Future<void> cancelTask() async {
    final taskId = state.task?.taskId;
    if (taskId == null) return;

    await _streamSub?.cancel();
    _streamSub = null;

    try {
      await _datasource.cancelTask(taskId);
    } catch (_) {}

    final updated = state.task?.copyWith(status: TaskStatus.cancelled);
    if (updated != null) {
      state = state.copyWith(task: updated);
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void reset() {
    _streamSub?.cancel();
    _streamSub = null;
    state = const AgentState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Stream subscription ──────────────────────────────────────────────────

  void _subscribeToStream(String taskId) {
    _streamSub?.cancel();
    _streamSub = _datasource.streamTask(taskId).listen(
      _handleEvent,
      onError: (e) {
        state = state.copyWith(error: e.toString());
      },
    );
  }

  void _handleEvent(AgentEventModel event) {
    final task = state.task;
    if (task == null) return;

    final agentType = event.agent != null ? _parseAgent(event.agent!) : null;

    switch (event.type) {
      case 'task.started':
        state = state.copyWith(
          task: task.copyWith(status: TaskStatus.planning),
        );
        break;

      case 'agent.started':
        if (agentType != null) {
          final steps = _upsertStep(
            task.steps,
            AgentStep(agent: agentType, status: AgentStatus.running),
          );
          state = state.copyWith(
            task: task.copyWith(status: TaskStatus.running, steps: steps),
            clearStreamingDelta: true,
          );
        }
        break;

      case 'agent.thinking':
        // Planner thinking — accumulate but don't show as full delta
        final text = event.data['text'] as String? ?? '';
        state = state.copyWith(
          streamingDelta: (state.streamingDelta ?? '') + text,
        );
        break;

      case 'agent.delta':
        final text = event.data['text'] as String? ?? '';
        state = state.copyWith(
          streamingDelta: (state.streamingDelta ?? '') + text,
        );
        break;

      case 'agent.tool_call':
        if (agentType != null) {
          final toolCall = ToolCallInfo(
            id:        event.data['id']   as String? ?? '',
            name:      event.data['name'] as String? ?? '',
            arguments: Map<String, dynamic>.from(
              event.data['arguments'] as Map? ?? {},
            ),
            isRunning: true,
          );
          final steps = _addToolCall(task.steps, agentType, toolCall);
          state = state.copyWith(task: task.copyWith(steps: steps));
        }
        break;

      case 'agent.tool_result':
        if (agentType != null) {
          final toolId = event.data['id'] as String? ?? '';
          final result = event.data['result'] as String?;
          final steps  = _updateToolCallResult(task.steps, agentType, toolId, result);
          state = state.copyWith(task: task.copyWith(steps: steps));
        }
        break;

      case 'agent.done':
        if (agentType != null) {
          final steps = _upsertStep(
            task.steps,
            _getStep(task.steps, agentType)?.copyWith(
                  status: AgentStatus.done,
                  output: state.streamingDelta,
                ) ??
                AgentStep(agent: agentType, status: AgentStatus.done),
          );
          state = state.copyWith(
            task: task.copyWith(steps: steps),
            clearStreamingDelta: true,
          );
        }
        break;

      case 'agent.error':
        if (agentType != null) {
          final errMsg = event.data['error'] as String? ?? 'Agent error';
          final steps  = _upsertStep(
            task.steps,
            AgentStep(
              agent:   agentType,
              status:  AgentStatus.error,
              message: errMsg,
            ),
          );
          state = state.copyWith(task: task.copyWith(steps: steps));
        }
        break;

      case 'task.done':
        final summary = event.data['summary'] as String?;
        state = state.copyWith(
          task: task.copyWith(
            status:      TaskStatus.done,
            finalOutput: summary,
          ),
          clearStreamingDelta: true,
        );
        break;

      case 'task.error':
        final errMsg = event.data['error'] as String? ?? 'Task failed';
        state = state.copyWith(
          task:  task.copyWith(status: TaskStatus.error, error: errMsg),
          error: errMsg,
        );
        break;

      case 'task.cancelled':
        state = state.copyWith(
          task: task.copyWith(status: TaskStatus.cancelled),
        );
        break;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  AgentType? _parseAgent(String raw) {
    try {
      return AgentType.values.firstWhere((a) => a.name == raw);
    } catch (_) {
      return null;
    }
  }

  AgentStep? _getStep(List<AgentStep> steps, AgentType agent) {
    try {
      return steps.lastWhere((s) => s.agent == agent);
    } catch (_) {
      return null;
    }
  }

  List<AgentStep> _upsertStep(List<AgentStep> steps, AgentStep updated) {
    final idx = steps.lastIndexWhere((s) => s.agent == updated.agent);
    if (idx == -1) return [...steps, updated];
    final list = List<AgentStep>.from(steps);
    list[idx] = updated;
    return list;
  }

  List<AgentStep> _addToolCall(
    List<AgentStep> steps,
    AgentType agent,
    ToolCallInfo toolCall,
  ) {
    final step = _getStep(steps, agent);
    if (step == null) return steps;
    return _upsertStep(
      steps,
      step.copyWith(toolCalls: [...step.toolCalls, toolCall]),
    );
  }

  List<AgentStep> _updateToolCallResult(
    List<AgentStep> steps,
    AgentType agent,
    String toolId,
    String? result,
  ) {
    final step = _getStep(steps, agent);
    if (step == null) return steps;
    final updatedCalls = step.toolCalls.map((tc) {
      if (tc.id == toolId) {
        return ToolCallInfo(
          id:        tc.id,
          name:      tc.name,
          arguments: tc.arguments,
          result:    result,
          isRunning: false,
        );
      }
      return tc;
    }).toList();
    return _upsertStep(steps, step.copyWith(toolCalls: updatedCalls));
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

// Keyed by projectId so each project has independent agent state
final agentProvider = StateNotifierProvider.family<AgentNotifier, AgentState, String>(
  (ref, projectId) => AgentNotifier(ref.read(agentDatasourceProvider)),
);
