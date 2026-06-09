import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/entities/terminal_session.dart';
import '../providers/terminal_provider.dart';
import '../widgets/terminal_output.dart';
import '../widgets/terminal_input_bar.dart';
import '../widgets/terminal_toolbar.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String projectId;
  const TerminalScreen({
    super.key,
    required this.sessionId,
    required this.projectId,
  });

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _scrollController = ScrollController();
  final _inputController  = TextEditingController();
  final _inputFocus       = FocusNode();
  bool _autoScroll = true;

  TerminalKey get _key =>
      TerminalKey(sessionId: widget.sessionId, projectId: widget.projectId);

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendCommand() {
    final cmd = _inputController.text.trim();
    if (cmd.isEmpty) return;
    ref.read(terminalProvider(_key).notifier).sendCommand(cmd);
    _inputController.clear();
    _scrollToBottom();
  }

  void _handleSpecialKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final notifier = ref.read(terminalProvider(_key).notifier);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        final cmd = notifier.navigateHistory(true);
        if (cmd != null) _inputController.text = cmd;
        break;
      case LogicalKeyboardKey.arrowDown:
        final cmd = notifier.navigateHistory(false);
        if (cmd != null) _inputController.text = cmd;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(terminalProvider(_key));
    final notifier = ref.read(terminalProvider(_key).notifier);

    // Auto-scroll when lines change
    ref.listen(terminalProvider(_key), (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Toolbar
            TerminalToolbar(
              sessionId: widget.sessionId,
              cwd:       session.currentDirectory,
              status:    session.status,
              onClear:   notifier.clearScreen,
              onReconnect: notifier.reconnect,
              onCtrlC:   notifier.sendCtrlC,
              onCtrlD:   notifier.sendCtrlD,
              onCtrlL:   notifier.sendCtrlL,
            ),

            // Output
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification) {
                    final atBottom = _scrollController.position.pixels >=
                        _scrollController.position.maxScrollExtent - 40;
                    if (_autoScroll != atBottom) {
                      setState(() => _autoScroll = atBottom);
                    }
                  }
                  return false;
                },
                child: TerminalOutput(
                  lines:            session.lines,
                  scrollController: _scrollController,
                ),
              ),
            ),

            // Auto-scroll indicator
            if (!_autoScroll)
              GestureDetector(
                onTap: () {
                  setState(() => _autoScroll = true);
                  _scrollToBottom();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: AppColors.primary.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_downward, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Scroll to bottom',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),

            // Status: Disconnected banner
            if (session.status == TerminalStatus.disconnected ||
                session.status == TerminalStatus.error)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppColors.error.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 14, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      session.status == TerminalStatus.disconnected
                          ? 'Disconnected'
                          : 'Connection error',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: notifier.reconnect,
                      child: const Text('Reconnect'),
                    ),
                  ],
                ),
              ),

            // Input bar
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _handleSpecialKey,
              child: TerminalInputBar(
                controller:  _inputController,
                focusNode:   _inputFocus,
                cwd:         session.currentDirectory,
                isConnected: session.isConnected,
                onSubmit:    _sendCommand,
                onCtrlC:     notifier.sendCtrlC,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
