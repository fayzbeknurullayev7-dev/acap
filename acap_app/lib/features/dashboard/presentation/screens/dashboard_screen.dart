import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _newSession() => const Uuid().v4();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final projectsState = ref.watch(projectsProvider);
    final userName = auth.user?.name ?? 'Foydalanuvchi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ACAP',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.go('/settings'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVar,
                backgroundImage: auth.user?.avatarUrl != null
                    ? NetworkImage(auth.user!.avatarUrl!)
                    : null,
                child: auth.user?.avatarUrl == null
                    ? Icon(Icons.person, color: AppColors.textSecondary)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.read(projectsProvider.notifier).loadProjects(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Salom, $userName 👋', style: AppTypography.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Bugun nima quramiz?',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _QuickActions(newSession: _newSession),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('So\'nggi loyihalar', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () => context.go('/projects'),
                  child: Text('Barchasi',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _RecentProjects(state: projectsState),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions ───────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final String Function() newSession;
  const _QuickActions({required this.newSession});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction('🤖', 'New Agent', AppColors.primary,
          () => context.go('/chat/${newSession()}')),
      _QuickAction('📁', 'Projects', AppColors.secondary,
          () => context.go('/projects')),
      _QuickAction('💻', 'Terminal', AppColors.tertiary,
          () => context.go('/terminal/${newSession()}')),
      _QuickAction('⚙️', 'Settings', AppColors.info,
          () => context.go('/settings')),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _QuickActionCard(action: actions[i])),
          if (i != actions.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _QuickAction {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.emoji, this.label, this.color, this.onTap);
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(action.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent projects ─────────────────────────────────────────────────────────

class _RecentProjects extends StatelessWidget {
  final ProjectsState state;
  const _RecentProjects({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.projects.isEmpty) {
      return Column(
        children: List.generate(3, (_) => const _ShimmerCard()),
      );
    }
    if (state.projects.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Text(
          'Hali loyiha yo\'q. Yangi loyiha yarating.',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    final recent = state.recent.take(5).toList();
    return Column(
      children: [
        for (final p in recent) _RecentProjectCard(project: p),
      ],
    );
  }
}

class _RecentProjectCard extends StatelessWidget {
  final Project project;
  const _RecentProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/projects/${project.projectId}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name,
                        style: AppTypography.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_relativeTime(project.lastActivity),
                        style: AppTypography.labelSmall),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(project.language,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'hozir';
    if (d.inMinutes < 60) return '${d.inMinutes} daqiqa oldin';
    if (d.inHours < 24) return '${d.inHours} soat oldin';
    return '${d.inDays} kun oldin';
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.surfaceVar,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
