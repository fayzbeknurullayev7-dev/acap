import 'package:equatable/equatable.dart';

enum TerminalStatus { connecting, connected, disconnected, error }

class TerminalSession extends Equatable {
  final String id;
  final String projectId;
  final TerminalStatus status;
  final List<TerminalLine> lines;
  final String currentDirectory;
  final List<String> history;   // command history
  final int historyIndex;

  const TerminalSession({
    required this.id,
    required this.projectId,
    this.status       = TerminalStatus.connecting,
    this.lines        = const [],
    this.currentDirectory = '~',
    this.history      = const [],
    this.historyIndex = -1,
  });

  TerminalSession copyWith({
    TerminalStatus? status,
    List<TerminalLine>? lines,
    String? currentDirectory,
    List<String>? history,
    int? historyIndex,
  }) {
    return TerminalSession(
      id:               id,
      projectId:        projectId,
      status:           status           ?? this.status,
      lines:            lines            ?? this.lines,
      currentDirectory: currentDirectory ?? this.currentDirectory,
      history:          history          ?? this.history,
      historyIndex:     historyIndex     ?? this.historyIndex,
    );
  }

  bool get isConnected => status == TerminalStatus.connected;

  @override
  List<Object?> get props => [id, status, lines.length];
}

enum LineType { output, error, command, system }

class TerminalLine extends Equatable {
  final String text;
  final LineType type;
  final DateTime timestamp;

  const TerminalLine({
    required this.text,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, type, timestamp];
}
