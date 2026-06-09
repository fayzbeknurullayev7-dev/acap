import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/entities/file_info.dart';
import '../providers/files_browser_provider.dart';

/// Project fayllarini tree ko'rinishida ko'rsatuvchi modal bottom sheet.
class FileBrowserSheet extends ConsumerStatefulWidget {
  final String projectId;
  const FileBrowserSheet({super.key, required this.projectId});

  /// showModalBottomSheet orqali ochish uchun yordamchi.
  static Future<void> open(BuildContext context, String projectId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FileBrowserSheet(projectId: projectId),
    );
  }

  @override
  ConsumerState<FileBrowserSheet> createState() => _FileBrowserSheetState();
}

class _FileBrowserSheetState extends ConsumerState<FileBrowserSheet> {
  @override
  void initState() {
    super.initState();
    // Sheet ochilganda fayllarni yuklaymiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchFiles(ref, widget.projectId);
    });
  }

  void _openFile(FileInfo file) {
    Navigator.of(context).pop();
    context.go('/editor/${file.id}?projectId=${widget.projectId}');
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(filesProvider);
    final isLoading = ref.watch(filesLoadingProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle + title
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Fayllar', style: AppTypography.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.textSecondary),
                    onPressed: () => fetchFiles(ref, widget.projectId),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildBody(files, isLoading, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    List<FileInfo> files,
    bool isLoading,
    ScrollController controller,
  ) {
    if (isLoading && files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Fayllar yo\'q',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final nodes = _buildTree(files);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: nodes.map((n) => _buildNode(n, 0)).toList(),
    );
  }

  // ── Tree qurish ───────────────────────────────────────────────
  // Path'larni katalog bo'yicha guruhlaymiz.
  List<_TreeNode> _buildTree(List<FileInfo> files) {
    final root = <String, _TreeNode>{};
    for (final file in files) {
      final parts = file.path.split('/');
      var level = root;
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        final isLeaf = i == parts.length - 1;
        final node = level.putIfAbsent(
          part,
          () => _TreeNode(name: part, isDir: !isLeaf),
        );
        if (isLeaf) {
          node.file = file;
        } else {
          level = node.children;
        }
      }
    }
    return _sortNodes(root.values.toList());
  }

  List<_TreeNode> _sortNodes(List<_TreeNode> nodes) {
    nodes.sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return nodes;
  }

  Widget _buildNode(_TreeNode node, int depth) {
    final pad = EdgeInsets.only(left: 16.0 + depth * 16, right: 16);
    if (node.isDir) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: pad.copyWith(top: 6, bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.folder, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(node.name, style: AppTypography.bodyMedium),
                ],
              ),
            ),
            ..._sortNodes(node.children.values.toList())
                .map((c) => _buildNode(c, depth + 1)),
          ],
        ),
      );
    }

    final file = node.file!;
    return InkWell(
      onTap: () => _openFile(file),
      child: Padding(
        padding: pad.copyWith(top: 8, bottom: 8),
        child: Row(
          children: [
            Icon(Icons.description_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(node.name, style: AppTypography.bodyMedium),
            ),
            Text(
              file.language,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeNode {
  final String name;
  final bool isDir;
  final Map<String, _TreeNode> children = {};
  FileInfo? file;

  _TreeNode({required this.name, required this.isDir});
}
