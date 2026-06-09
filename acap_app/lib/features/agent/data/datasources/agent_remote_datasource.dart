// lib/features/agent/data/datasources/agent_remote_datasource.dart

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/agent_event.dart';

abstract class AgentRemoteDatasource {
  Future<String> submitTask({
    required String projectId,
    required String sessionId,
    required String userMessage,
    List<String>? selectedAgents,
  });

  Stream<AgentEventModel> streamTask(String taskId);

  Future<void> cancelTask(String taskId);

  Future<Map<String, dynamic>> getTask(String taskId);
}

class AgentRemoteDatasourceImpl implements AgentRemoteDatasource {
  static const _storage = FlutterSecureStorage();

  // ── Submit ────────────────────────────────────────────────────────────

  @override
  Future<String> submitTask({
    required String projectId,
    required String sessionId,
    required String userMessage,
    List<String>? selectedAgents,
  }) async {
    final res = await DioClient.agent.post(
      '/agent/tasks',
      data: {
        'project_id':      projectId,
        'session_id':      sessionId,
        'user_message':    userMessage,
        if (selectedAgents != null) 'selected_agents': selectedAgents,
      },
    );
    return res.data['task_id'] as String;
  }

  // ── Stream ────────────────────────────────────────────────────────────

  @override
  Stream<AgentEventModel> streamTask(String taskId) async* {
    final token = await _storage.read(key: AppConstants.accessToken) ?? '';
    final uri = Uri.parse(
      '${AppConstants.agentWsUrl}/agent/tasks/$taskId/stream?token=$token',
    );

    final channel = WebSocketChannel.connect(uri);
    await channel.ready;

    final ctrl = StreamController<AgentEventModel>();

    final sub = channel.stream.listen(
      (raw) {
        try {
          final json = jsonDecode(raw as String) as Map<String, dynamic>;
          final event = AgentEventModel.fromJson(json);
          ctrl.add(event);
          // Auto-close on terminal events
          final terminal = {'task.done', 'task.error', 'task.cancelled'};
          if (terminal.contains(event.type)) {
            ctrl.close();
          }
        } catch (_) {}
      },
      onError: (e) => ctrl.addError(e),
      onDone:  ()  => ctrl.close(),
      cancelOnError: false,
    );

    ctrl.onCancel = () {
      sub.cancel();
      channel.sink.close();
    };

    yield* ctrl.stream;
  }

  // ── Cancel ────────────────────────────────────────────────────────────

  @override
  Future<void> cancelTask(String taskId) async {
    await DioClient.agent.post('/agent/tasks/$taskId/cancel');
  }

  // ── Get status ────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getTask(String taskId) async {
    final res = await DioClient.agent.get('/agent/tasks/$taskId');
    return res.data as Map<String, dynamic>;
  }
}
