import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/entities/project.dart';
import '../providers/projects_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectsProvider);

    final filtered = state.projects
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Projects', style: AppTypography.titleLarge),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openCreateSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.read(projectsProvider.notifier).loadProjects(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                style: AppTypography.bodyMedium,
                cursorColor: AppColors.primary,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Loyihalarni qidirish...',
                  hintStyle: TextStyle(color: AppColors.textDisabled),
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(state, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProjectsState state, List<Project> filtered) {
    if (state.isLoading && state.projects.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state.error != null && state.projects.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(projectsProvider.notifier).loadProjects(),
      );
    }
    if (filtered.isEmpty) {
      return const _EmptyView();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ProjectCard(project: filtered[i]),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CreateProjectSheet(),
    );
  }
}

// ── Project card ────────────────────────────────────────────────────────────

class _ProjectCard extends ConsumerWidget {
  final Project project;
  const _ProjectCard({required this.project});

  String _newSession() => const Uuid().v4();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.go('/projects/${project.projectId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _LanguageBadge(language: project.language),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                project.description,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.smart_toy_outlined,
                  label: 'Agent',
                  onTap: () => context.go(
                    '/chat/${_newSession()}?projectId=${project.projectId}',
                  ),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Editor',
                  onTap: () => context.go('/projects/${project.projectId}'),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.terminal_outlined,
                  label: 'Terminal',
                  onTap: () => context.go('/terminal/${_newSession()}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVar,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(label, style: AppTypography.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final String language;
  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        language,
        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ── Empty / Error ───────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.folder_open, size: 64, color: AppColors.textDisabled),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Hali loyiha yo\'q. Yangi loyiha yarating.',
            style: AppTypography.bodyLarge
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('Qayta urinish',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Create project bottom sheet ─────────────────────────────────────────────

class CreateProjectSheet extends ConsumerStatefulWidget {
  const CreateProjectSheet({super.key});

  @override
  ConsumerState<CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends ConsumerState<CreateProjectSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _language = 'dart';
  bool _submitting = false;

  static const _languages = [
    'dart', 'python', 'javascript', 'typescript', 'go',
    'rust', 'java', 'kotlin', 'cpp', 'html', 'css',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _submitting = true);
    final project = await ref.read(projectsProvider.notifier).createProject(
          name: name,
          language: _language,
          description: _descController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (project != null) {
      Navigator.pop(context);
      context.go('/projects/${project.projectId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Yangi loyiha', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: AppTypography.bodyMedium,
              cursorColor: AppColors.primary,
              decoration: _inputDecoration('Project nomi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: AppTypography.bodyMedium,
              cursorColor: AppColors.primary,
              decoration: _inputDecoration('Tavsif (ixtiyoriy)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _language,
              dropdownColor: AppColors.surfaceVar,
              style: AppTypography.bodyMedium,
              decoration: _inputDecoration('Dasturlash tili'),
              items: _languages
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => _language = v ?? 'dart'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Yaratish',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textDisabled),
      filled: true,
      fillColor: AppColors.surfaceVar,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
