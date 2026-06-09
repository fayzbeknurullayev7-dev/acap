// lib/features/agent/presentation/screens/agent_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/agent_task.dart';
import '../providers/agent_provider.dart';
import '../widgets/agent_input_bar.dart';
import '../widgets/agent_pipeline_view.dart';
import '../widgets/agent_result_view.dart';
import '../widgets/agent_status_header.dart';

class AgentScreen extends ConsumerWidget {
  final String projectId;
  final String sessionId;
  final String? projectName;

  const AgentScreen({
    super.key,
    required this.projectId,
    required this.sessionId,
    this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor:  AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: AppColors.textPrimary),
        ),
        title: Column(
          children: [
            Text(
              projectName ?? 'Agent Orchestrator',
              style: TextStyle(
                color:      AppColors.textPrimary,
                fontSize:   15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _statusLabel(state),
              style: TextStyle(
                color:    _statusColor(state),
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (state.isActive)
            TextButton.icon(
              onPressed: () =>
                  ref.read(agentProvider(projectId).notifier).cancelTask(),
              icon: Icon(Icons.stop_rounded, color: AppColors.error, size: 16),
              label: Text(
                'Stop',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          if (!state.isActive && state.hasTask)
            IconButton(
              onPressed: () =>
                  ref.read(agentProvider(projectId).notifier).reset(),
              icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // ── Main content ─────────────────────────────────────────────
          Expanded(
            child: state.hasTask
                ? _TaskView(projectId: projectId)
                : _EmptyState(
                    onSuggestedPrompt: (p) => _submit(context, ref, p),
                  ),
          ),

          // ── Error banner ─────────────────────────────────────────────
          if (state.error != null)
            _ErrorBanner(
              message:   state.error!,
              onDismiss: () =>
                  ref.read(agentProvider(projectId).notifier).clearError(),
            ),

          // ── Input bar ────────────────────────────────────────────────
          if (!state.isActive || state.task == null)
            AgentInputBar(
              isLoading: state.isSubmitting,
              onSend:    (msg) => _submit(context, ref, msg),
            ),
        ],
      ),
    );
  }

  void _submit(BuildContext context, WidgetRef ref, String message) {
    if (message.trim().isEmpty) return;
    ref.read(agentProvider(projectId).notifier).submitTask(
          projectId:   projectId,
          sessionId:   sessionId,
          userMessage: message.trim(),
        );
  }

  String _statusLabel(AgentState state) {
    if (state.isSubmitting) return 'Submitting…';
    switch (state.task?.status) {
      case TaskStatus.queued:    return 'Queued';
      case TaskStatus.planning:  return 'Planning…';
      case TaskStatus.running:   return 'Agents running…';
      case TaskStatus.reviewing: return 'Reviewing…';
      case TaskStatus.done:      return 'Completed';
      case TaskStatus.error:     return 'Error';
      case TaskStatus.cancelled: return 'Cancelled';
      default:                   return 'Ready';
    }
  }

  Color _statusColor(AgentState state) {
    switch (state.task?.status) {
      case TaskStatus.done:      return AppColors.success;
      case TaskStatus.error:     return AppColors.error;
      case TaskStatus.cancelled: return AppColors.textSecondary;
      case TaskStatus.running:
      case TaskStatus.planning:  return AppColors.primary;
      default:                   return AppColors.textSecondary;
    }
  }
}

// ── Task view — shows pipeline + result ────────────────────────────────────

class _TaskView extends ConsumerWidget {
  final String projectId;
  const _TaskView({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentProvider(projectId));
    final task  = state.task!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User prompt card
          _PromptCard(message: task.userMessage),
          const SizedBox(height: 16),

          // Status header
          AgentStatusHeader(task: task),
          const SizedBox(height: 16),

          // Pipeline (agent steps)
          if (task.steps.isNotEmpty) ...[
            AgentPipelineView(
              steps:           task.steps,
              streamingDelta:  state.streamingDelta,
              activeAgentType: _activeAgent(task),
            ),
            const SizedBox(height: 16),
          ],

          // Final result
          if (task.isDone && task.finalOutput != null)
            AgentResultView(output: task.finalOutput!),
        ],
      ),
    );
  }

  AgentType? _activeAgent(AgentTask task) {
    try {
      return task.steps
          .lastWhere((s) => s.status == AgentStatus.running)
          .agent;
    } catch (_) {
      return null;
    }
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final void Function(String) onSuggestedPrompt;
  const _EmptyState({required this.onSuggestedPrompt});

  static const _prompts = [
    ('🏗️  Yangi loyiha', 'Flutter + FastAPI asosida CRUD app yarating. Folder struktura, models, API qatlami bilan.'),
    ('🐛  Xato tuzating',  'Quyidagi error ni tahlil qilib, root cause va fix yozing'),
    ('🧪  Test yozing',    'Ushbu modul uchun to\'liq unit va integration testlar yozing'),
    ('🚀  Deploy qiling',  'Ushbu loyiha uchun Dockerfile, docker-compose va Railway deploy config yarating'),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_mosaic_rounded,
                color: Colors.white, size: 32,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 20),

            Text(
              'Multi-Agent Orchestrator',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 8),

            Text(
              '10 ta ixtisoslashgan agent parallel ishlaydi',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ).animate(delay: 150.ms).fadeIn(),

            const SizedBox(height: 32),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount:   2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 10,
              mainAxisSpacing:  10,
              children: [
                for (int i = 0; i < _prompts.length; i++)
                  _SuggestedCard(
                    label:  _prompts[i].$1,
                    prompt: _prompts[i].$2,
                    delay:  (200 + i * 60).ms,
                    onTap:  () => onSuggestedPrompt(_prompts[i].$2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  final String label;
  final String prompt;
  final Duration delay;
  final VoidCallback onTap;

  const _SuggestedCard({
    required this.label,
    required this.prompt,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
      ),
    ).animate(delay: delay).fadeIn(duration: 250.ms).slideY(begin: 0.1);
  }
}

// ── Prompt card ────────────────────────────────────────────────────────────

class _PromptCard extends StatelessWidget {
  final String message;
  const _PromptCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 16, color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Error banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.error, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: AppColors.error, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
