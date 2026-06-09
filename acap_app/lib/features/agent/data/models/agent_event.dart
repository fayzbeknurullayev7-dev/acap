// lib/features/agent/data/models/agent_event.dart

class AgentEventModel {
  final String type;
  final String taskId;
  final String? agent;
  final Map<String, dynamic> data;

  const AgentEventModel({
    required this.type,
    required this.taskId,
    this.agent,
    required this.data,
  });

  factory AgentEventModel.fromJson(Map<String, dynamic> json) {
    return AgentEventModel(
      type:   json['type']    as String,
      taskId: json['task_id'] as String,
      agent:  json['agent']   as String?,
      data:   Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }
}
