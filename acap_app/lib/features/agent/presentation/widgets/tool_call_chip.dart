// lib/features/agent/presentation/widgets/tool_call_chip.dart

import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/agent_task.dart';

class ToolCallChip extends StatelessWidget {
  final ToolCallInfo toolCall;
  const ToolCallChip({super.key, required this.toolCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        toolCall.isRunning
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: toolCall.isRunning
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            toolCall.isRunning
                ? Icons.play_circle_outline_rounded
                : Icons.check_circle_outline_rounded,
            size:  12,
            color: toolCall.isRunning ? AppColors.primary : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            toolCall.name,
            style: TextStyle(
              color:    AppColors.textSecondary,
              fontSize: 11,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }
}
