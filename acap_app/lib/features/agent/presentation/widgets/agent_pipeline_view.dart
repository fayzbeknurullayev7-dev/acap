// lib/features/agent/presentation/widgets/agent_pipeline_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/agent_task.dart';
import 'agent_step_card.dart';

class AgentPipelineView extends StatelessWidget {
  final List<AgentStep> steps;
  final String? streamingDelta;
  final AgentType? activeAgentType;

  const AgentPipelineView({
    super.key,
    required this.steps,
    this.streamingDelta,
    this.activeAgentType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.account_tree_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Agent Pipeline',
              style: TextStyle(
                color:      AppColors.textSecondary,
                fontSize:   12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${steps.length}',
                style: TextStyle(
                  color:    AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Steps list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final step = steps[i];
            final isActive = step.agent == activeAgentType &&
                step.status == AgentStatus.running;
            return AgentStepCard(
              key:             ValueKey('${step.agent.name}-$i'),
              step:            step,
              isActive:        isActive,
              streamingDelta:  isActive ? streamingDelta : null,
            ).animate(delay: (i * 50).ms).fadeIn(duration: 200.ms).slideX(begin: -0.05);
          },
        ),
      ],
    );
  }
}
