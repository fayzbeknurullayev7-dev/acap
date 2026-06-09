// lib/features/agent/presentation/widgets/agent_step_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/agent_task.dart';
import 'tool_call_chip.dart';

class AgentStepCard extends StatelessWidget {
  final AgentStep step;
  final bool isActive;
  final String? streamingDelta;

  const AgentStepCard({
    super.key,
    required this.step,
    this.isActive = false,
    this.streamingDelta,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primary.withOpacity(0.4) : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                // Emoji avatar
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color:        _statusBgColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isActive
                        ? _SpinnerEmoji(emoji: step.agent.emoji)
                        : Text(step.agent.emoji,
                            style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.agent.label,
                        style: TextStyle(
                          color:      AppColors.textPrimary,
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _statusText,
                        style: TextStyle(
                          color:    _statusColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status icon
                _StatusIcon(status: step.status, isActive: isActive),
              ],
            ),
          ),

          // ── Tool calls ──────────────────────────────────────────────
          if (step.toolCalls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: step.toolCalls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) =>
                    ToolCallChip(toolCall: step.toolCalls[i]),
              ),
            ),
          ],

          // ── Streaming output ────────────────────────────────────────
          if (isActive && streamingDelta != null && streamingDelta!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                streamingDelta!.length > 300
                    ? '…${streamingDelta!.substring(streamingDelta!.length - 300)}'
                    : streamingDelta!,
                style: TextStyle(
                  color:      AppColors.textSecondary,
                  fontSize:   12,
                  fontFamily: 'JetBrainsMono',
                  height:     1.5,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // ── Done output preview ──────────────────────────────────────
          if (!isActive && step.status == AgentStatus.done &&
              step.output != null && step.output!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Text(
                step.output!.length > 120
                    ? '${step.output!.substring(0, 120)}…'
                    : step.output!,
                style: TextStyle(
                  color:    AppColors.textSecondary,
                  fontSize: 12,
                  height:   1.4,
                ),
              ),
            ),
          ],

          // ── Error message ────────────────────────────────────────────
          if (step.status == AgentStatus.error && step.message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Text(
                step.message,
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String get _statusText {
    if (isActive) return 'Running…';
    switch (step.status) {
      case AgentStatus.idle:    return 'Waiting';
      case AgentStatus.running: return 'Running…';
      case AgentStatus.waiting: return 'Waiting for dependency';
      case AgentStatus.done:    return 'Completed';
      case AgentStatus.error:   return 'Failed';
      case AgentStatus.skipped: return 'Skipped';
    }
  }

  Color get _statusColor {
    if (isActive) return AppColors.primary;
    switch (step.status) {
      case AgentStatus.done:    return AppColors.success;
      case AgentStatus.error:   return AppColors.error;
      case AgentStatus.skipped: return AppColors.textSecondary;
      default:                  return AppColors.textSecondary;
    }
  }

  Color get _statusBgColor {
    if (isActive) return AppColors.primary;
    switch (step.status) {
      case AgentStatus.done:  return AppColors.success;
      case AgentStatus.error: return AppColors.error;
      default:                return AppColors.textSecondary;
    }
  }
}

// ── Spinner emoji ──────────────────────────────────────────────────────────

class _SpinnerEmoji extends StatelessWidget {
  final String emoji;
  const _SpinnerEmoji({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 18))
        .animate(onPlay: (ctrl) => ctrl.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white54);
  }
}

// ── Status icon ────────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final AgentStatus status;
  final bool isActive;

  const _StatusIcon({required this.status, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      );
    }
    switch (status) {
      case AgentStatus.done:
        return Icon(Icons.check_circle_rounded,
            size: 18, color: AppColors.success);
      case AgentStatus.error:
        return Icon(Icons.error_rounded, size: 18, color: AppColors.error);
      case AgentStatus.skipped:
        return Icon(Icons.skip_next_rounded,
            size: 18, color: AppColors.textSecondary);
      default:
        return Icon(Icons.circle_outlined,
            size: 18, color: AppColors.textSecondary);
    }
  }
}
