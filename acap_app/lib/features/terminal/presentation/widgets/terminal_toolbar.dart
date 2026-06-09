import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/entities/terminal_session.dart';

class TerminalToolbar extends StatelessWidget {
  final String sessionId;
  final String cwd;
  final TerminalStatus status;
  final VoidCallback onClear;
  final VoidCallback onReconnect;
  final VoidCallback onCtrlC;
  final VoidCallback onCtrlD;
  final VoidCallback onCtrlL;

  const TerminalToolbar({
    super.key,
    required this.sessionId,
    required this.cwd,
    required this.status,
    required this.onClear,
    required this.onReconnect,
    required this.onCtrlC,
    required this.onCtrlD,
    required this.onCtrlL,
  });

  Color get _statusColor {
    switch (status) {
      case TerminalStatus.connected:    return AppColors.success;
      case TerminalStatus.connecting:   return AppColors.warning;
      case TerminalStatus.disconnected: return AppColors.textDisabled;
      case TerminalStatus.error:        return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (status) {
      case TerminalStatus.connected:    return 'Connected';
      case TerminalStatus.connecting:   return 'Connecting...';
      case TerminalStatus.disconnected: return 'Disconnected';
      case TerminalStatus.error:        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.textSecondary,
            onPressed: () => context.pop(),
          ),

          // Terminal icon + status
          const Icon(Icons.terminal_rounded, size: 18, color: AppColors.tertiary),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terminal',
                style: AppTypography.bodyMedium.copyWith(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _statusLabel,
                    style: AppTypography.labelSmall.copyWith(color: _statusColor),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Quick control buttons
          _ControlChip(label: 'Ctrl+C', onTap: onCtrlC),
          _ControlChip(label: 'Ctrl+D', onTap: onCtrlD),
          _ControlChip(label: 'Clear', onTap: onClear),
        ],
      ),
    );
  }
}

class _ControlChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ControlChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceVar,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
