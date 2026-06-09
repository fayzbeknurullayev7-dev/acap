import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/terminal_session.dart';

class TerminalNotifier extends StateNotifier<TerminalSession> {
  final String sessionId;
  final String projectId;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  TerminalNotifier({required this.sessionId, required this.projectId})
      : super(TerminalSession(id: sessionId, projectId: projectId)) {
    _connect();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  // ── Connect ───────────────────────────────────────────────────

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConstants.terminalWsUrl}/api/v1/terminal/$sessionId'),
      );
      state = state.copyWith(status: TerminalStatus.connecting);

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone:  _onDone,
      );

      _addSystemLine('Connecting to terminal...');
    } catch (e) {
      state = state.copyWith(status: TerminalStatus.error);
      _addSystemLine('Connection failed: $e');
    }
  }

  void reconnect() {
    _sub?.cancel();
    _channel?.sink.close();
    _connect();
  }

  // ── WebSocket messages ────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String;

      switch (type) {
        case 'connected':
          state = state.copyWith(status: TerminalStatus.connected);
          _addSystemLine('Connected. Shell ready.');
          break;

        case 'output':
          final data = msg['data'] as String;
          _appendOutput(data, LineType.output);
          break;

        case 'error':
          final data = msg['data'] as String;
          _appendOutput(data, LineType.error);
          break;

        case 'cwd':
          final cwd = msg['path'] as String;
          state = state.copyWith(currentDirectory: cwd);
          break;
      }
    } catch (_) {
      // Raw text output (non-JSON PTY output)
      _appendOutput(raw.toString(), LineType.output);
    }
  }

  void _onError(dynamic error) {
    state = state.copyWith(status: TerminalStatus.error);
    _addSystemLine('Connection error: $error');
  }

  void _onDone() {
    state = state.copyWith(status: TerminalStatus.disconnected);
    _addSystemLine('Terminal disconnected.');
  }

  // ── Send command ──────────────────────────────────────────────

  void sendCommand(String command) {
    if (!state.isConnected) {
      _addSystemLine('Not connected. Reconnecting...');
      reconnect();
      return;
    }

    // Add to history
    final history = [command, ...state.history.take(99)].toList();
    state = state.copyWith(history: history, historyIndex: -1);

    // Echo command to output
    _appendOutput('${state.currentDirectory}\$ $command\n', LineType.command);

    // Send to backend
    _channel!.sink.add(jsonEncode({
      'type': 'input',
      'data': '$command\n',
    }));
  }

  void sendRaw(String data) {
    if (state.isConnected) {
      _channel!.sink.add(jsonEncode({'type': 'input', 'data': data}));
    }
  }

  void sendCtrlC() => sendRaw('\x03');
  void sendCtrlD() => sendRaw('\x04');
  void sendCtrlL() {
    clearScreen();
    sendRaw('\x0c');
  }

  // ── History navigation ────────────────────────────────────────

  String? navigateHistory(bool up) {
    final history = state.history;
    if (history.isEmpty) return null;

    int newIdx;
    if (up) {
      newIdx = (state.historyIndex + 1).clamp(0, history.length - 1);
    } else {
      newIdx = state.historyIndex - 1;
      if (newIdx < 0) {
        state = state.copyWith(historyIndex: -1);
        return '';
      }
    }

    state = state.copyWith(historyIndex: newIdx);
    return history[newIdx];
  }

  // ── Output ────────────────────────────────────────────────────

  void _appendOutput(String text, LineType type) {
    // Split multi-line output
    final newLines = text.split('\n').where((l) => l.isNotEmpty).map(
      (l) => TerminalLine(text: l, type: type, timestamp: DateTime.now()),
    ).toList();

    final updated = [...state.lines, ...newLines];
    // Keep last 1000 lines max
    final trimmed = updated.length > 1000
        ? updated.sublist(updated.length - 1000)
        : updated;

    state = state.copyWith(lines: trimmed);
  }

  void _addSystemLine(String text) {
    _appendOutput(text, LineType.system);
  }

  void clearScreen() {
    state = state.copyWith(lines: []);
  }
}

// ── Provider key ────────────────────────────────────────────────────────────

/// Family key — sessionId va projectId ni alohida ushlaydi.
/// Avval projectId = sessionId qilib xato berilardi.
class TerminalKey extends Equatable {
  final String sessionId;
  final String projectId;
  const TerminalKey({required this.sessionId, required this.projectId});

  @override
  List<Object> get props => [sessionId, projectId];
}

// ── Providers ─────────────────────────────────────────────────────────────

final terminalProvider = StateNotifierProvider.family<
    TerminalNotifier, TerminalSession, TerminalKey>(
  (ref, key) => TerminalNotifier(
    sessionId: key.sessionId,
    projectId: key.projectId,
  ),
);
