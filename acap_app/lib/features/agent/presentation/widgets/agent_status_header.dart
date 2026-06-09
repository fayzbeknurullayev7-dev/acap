// lib/features/agent/presentation/widgets/agent_status_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/agent_task.dart';

class AgentStatusHeader extends StatelessWidget {
  final AgentTask task;
  const AgentStatusHeader({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final done    = task.steps.where((s) => s.status == AgentStatus.done).length;
    final total   = task.steps.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              _statusIcon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusTitle,
                  style: TextStyle(
                    color:      AppColors.textPrimary,
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (total > 0)
                Text(
                  '$done/$total agents',
                  style: TextStyle(
                    color:    AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          // Progress bar
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:            task.isActive ? null : progress,
                minHeight:        4,
                backgroundColor:  AppColors.border,
                valueColor: AlwaysStoppedAnimation(_progressColor),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget get _statusIcon {
    switch (task.status) {
      case TaskStatus.done:
        return Icon(Icons.check_circle_rounded,
            size: 18, color: AppColors.success);
      case TaskStatus.error:
        return Icon(Icons.error_rounded, size: 18, color: AppColors.error);
      case TaskStatus.cancelled:
        return Icon(Icons.cancel_rounded,
            size: 18, color: AppColors.textSecondary);
      default:
        return SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        );
    }
  }

  String get _statusTitle {
    switch (task.status) {
      case TaskStatus.queued:    return 'Task queued…';
      case TaskStatus.planning:  return 'Planner analyzing task…';
      case TaskStatus.running:   return 'Agents working in parallel…';
      case TaskStatus.reviewing: return 'Reviewer checking output…';
      case TaskStatus.done:      return 'All agents completed!';
      case TaskStatus.error:     return 'Task failed';
      case TaskStatus.cancelled: return 'Task cancelled';
    }
  }

  Color get _progressColor {
    switch (task.status) {
      case TaskStatus.done:      return AppColors.success;
      case TaskStatus.error:     return AppColors.error;
      default:                   return AppColors.primary;
    }
  }
}
