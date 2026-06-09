import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../providers/editor_provider.dart';
import '../widgets/editor_tab_bar.dart';
import '../widgets/code_editor_view.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/editor_keyboard_bar.dart';
import '../widgets/ai_suggestion_overlay.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String fileId;
  final String projectId;
  const EditorScreen({
    super.key,
    required this.fileId,
    required this.projectId,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).openFile(widget.fileId, widget.projectId);
    });
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(editorProvider);
    if (!state.hasUnsavedChanges) return true;

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Unsaved changes'),
        content: const Text('Save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true) {
      await ref.read(editorProvider.notifier).saveActiveFile();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);

    return PopScope(
      onPopInvoked: (_) => _onWillPop(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top toolbar ──────────────────────────────────────
              EditorToolbar(
                fileName: editorState.activeFile?.name ?? '',
                language: editorState.activeFile?.language,
                isDirty:  editorState.activeTab?.isDirty ?? false,
                onSave:   () => ref.read(editorProvider.notifier).saveActiveFile(),
              ),

              // ── Tab bar ──────────────────────────────────────────
              if (editorState.tabs.isNotEmpty)
                EditorTabBar(
                  tabs:        editorState.tabs,
                  activeTabId: editorState.activeTabId,
                  onTabTap:    (id) => ref.read(editorProvider.notifier).switchTab(id),
                  onTabClose:  (id) => ref.read(editorProvider.notifier).closeTab(id),
                ),

              // ── Editor body ──────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    if (editorState.isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    else if (editorState.activeFile != null)
                      CodeEditorView(
                        file: editorState.activeFile!,
                        onChanged: (content) => ref
                            .read(editorProvider.notifier)
                            .onContentChanged(editorState.activeTabId!, content),
                      )
                    else
                      _EmptyEditor(),

                    // AI suggestion overlay
                    if (editorState.showAiSuggestion &&
                        editorState.aiSuggestion != null)
                      AiSuggestionOverlay(
                        suggestion: editorState.aiSuggestion!,
                        onAccept: () =>
                            ref.read(editorProvider.notifier).acceptAiSuggestion(),
                        onDismiss: () =>
                            ref.read(editorProvider.notifier).dismissAiSuggestion(),
                      ),
                  ],
                ),
              ),

              // ── Mobile code keyboard bar ─────────────────────────
              const EditorKeyboardBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code_rounded, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'No file open',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
