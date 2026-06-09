import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../providers/projects_provider.dart';
import '../widgets/file_browser_sheet.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  String _newSession() => const Uuid().v4();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectsProvider);
    final matches =
        state.projects.where((p) => p.projectId == projectId).toList();
    final project = matches.isEmpty ? null : matches.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/projects'),
        ),
        title: Text(project?.name ?? 'Project',
            style: AppTypography.titleLarge),
        actions: [
          if (project != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (project != null) ...[
            Text(
              project.description.isEmpty
                  ? 'Tavsif yo\'q'
                  : project.description,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
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
          const SizedBox(height: 24),
          _ActionTile(
            icon: Icons.smart_toy_outlined,
            title: 'Agent',
            subtitle: 'AI agent bilan kod yozish',
            onTap: () => context.go(
              '/chat/${_newSession()}?projectId=$projectId',
            ),
          ),
          _ActionTile(
            icon: Icons.edit_note_outlined,
            title: 'Editor 📝',
            subtitle: 'Fayllarni ko\'rish va tahrirlash',
            onTap: () => FileBrowserSheet.open(context, projectId),
          ),
          _ActionTile(
            icon: Icons.terminal_outlined,
            title: 'Terminal 💻',
            subtitle: 'Buyruqlar bajarish',
            onTap: () => context.go(
              '/terminal/${_newSession()}?projectId=$projectId',
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Loyihani o\'chirish',
            style: AppTypography.titleMedium),
        content: Text(
          'Bu amalni qaytarib bo\'lmaydi. Davom etilsinmi?',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Bekor',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(projectsProvider.notifier)
                  .deleteProject(projectId);
              if (context.mounted) context.go('/projects');
            },
            child: Text('O\'chirish', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTypography.labelSmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
