import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

class TerminalInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String cwd;
  final bool isConnected;
  final VoidCallback onSubmit;
  final VoidCallback onCtrlC;

  const TerminalInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.cwd,
    required this.isConnected,
    required this.onSubmit,
    required this.onCtrlC,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          // Prompt
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '$cwd\$',
              style: AppTypography.code.copyWith(
                color: AppColors.success,
                fontSize: 13,
              ),
            ),
          ),

          // Input
          Expanded(
            child: TextField(
              controller:       controller,
              focusNode:        focusNode,
              enabled:          isConnected,
              style:            AppTypography.code.copyWith(fontSize: 13),
              cursorColor:      AppColors.primary,
              decoration: const InputDecoration(
                border:             InputBorder.none,
                enabledBorder:      InputBorder.none,
                focusedBorder:      InputBorder.none,
                isDense:            true,
                contentPadding:     EdgeInsets.zero,
                fillColor:          Colors.transparent,
                filled:             false,
              ),
              onSubmitted: (_) => onSubmit(),
              textInputAction: TextInputAction.send,
            ),
          ),

          // Ctrl+C
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            color: AppColors.error,
            onPressed: isConnected ? onCtrlC : null,
            tooltip: 'Ctrl+C',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          // Send
          IconButton(
            icon: const Icon(Icons.send_rounded, size: 18),
            color: AppColors.primary,
            onPressed: isConnected ? onSubmit : null,
            tooltip: 'Enter',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
