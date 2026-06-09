import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/code_file.dart';
import '../../data/datasources/editor_remote_datasource.dart';

// ── Open Tabs State ───────────────────────────────────────────────────────

class EditorState {
  final List<EditorTab> tabs;
  final String? activeTabId;      // fileId of active tab
  final Map<String, CodeFile> loadedFiles;  // fileId → CodeFile
  final bool isLoading;
  final String? error;
  final String? aiSuggestion;     // inline AI autocomplete
  final bool showAiSuggestion;

  const EditorState({
    this.tabs            = const [],
    this.activeTabId,
    this.loadedFiles     = const {},
    this.isLoading       = false,
    this.error,
    this.aiSuggestion,
    this.showAiSuggestion = false,
  });

  CodeFile? get activeFile =>
      activeTabId != null ? loadedFiles[activeTabId] : null;

  EditorTab? get activeTab {
    for (final t in tabs) {
      if (t.fileId == activeTabId) return t;
    }
    return null;
  }

  bool get hasUnsavedChanges => tabs.any((t) => t.isDirty);

  EditorState copyWith({
    List<EditorTab>? tabs,
    String? activeTabId,
    bool clearActiveTab = false,
    Map<String, CodeFile>? loadedFiles,
    bool? isLoading,
    String? error,
    String? aiSuggestion,
    bool? showAiSuggestion,
  }) {
    return EditorState(
      tabs:             tabs             ?? this.tabs,
      activeTabId:      clearActiveTab ? null : (activeTabId ?? this.activeTabId),
      loadedFiles:      loadedFiles      ?? this.loadedFiles,
      isLoading:        isLoading        ?? this.isLoading,
      error:            error,
      aiSuggestion:     aiSuggestion     ?? this.aiSuggestion,
      showAiSuggestion: showAiSuggestion ?? this.showAiSuggestion,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────

class EditorNotifier extends StateNotifier<EditorState> {
  final EditorRemoteDatasource _datasource;
  Timer? _autoSaveTimer;
  Timer? _aiDebounceTimer;

  EditorNotifier(this._datasource) : super(const EditorState());

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _aiDebounceTimer?.cancel();
    super.dispose();
  }

  // ── Open / close tabs ────────────────────────────────────────────────

  Future<void> openFile(String fileId, String projectId) async {
    // Already open — just switch
    if (state.loadedFiles.containsKey(fileId)) {
      state = state.copyWith(activeTabId: fileId);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final file = await _datasource.openFile(fileId, projectId);
      final tab = EditorTab(
        fileId:   file.id,
        path:     file.path,
        name:     file.name,
        language: file.language,
      );

      final newTabs    = [...state.tabs, tab];
      final newLoaded  = {...state.loadedFiles, file.id: file};

      state = state.copyWith(
        tabs:        newTabs,
        loadedFiles: newLoaded,
        activeTabId: file.id,
        isLoading:   false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void closeTab(String fileId) {
    final tabs = state.tabs.where((t) => t.fileId != fileId).toList();
    final loaded = Map<String, CodeFile>.from(state.loadedFiles)..remove(fileId);

    String? newActive;
    if (state.activeTabId == fileId && tabs.isNotEmpty) {
      newActive = tabs.last.fileId;
    } else if (tabs.isNotEmpty) {
      newActive = state.activeTabId;
    }

    state = state.copyWith(
      tabs:           tabs,
      loadedFiles:    loaded,
      activeTabId:    newActive,
      clearActiveTab: tabs.isEmpty,
    );
  }

  void switchTab(String fileId) {
    state = state.copyWith(activeTabId: fileId);
  }

  // ── Edit ─────────────────────────────────────────────────────────────

  void onContentChanged(String fileId, String newContent) {
    final file = state.loadedFiles[fileId];
    if (file == null) return;

    final updatedFile = file.copyWith(content: newContent, isDirty: true);
    final updatedLoaded = {...state.loadedFiles, fileId: updatedFile};
    final updatedTabs = state.tabs
        .map((t) => t.fileId == fileId ? t.copyWith(isDirty: true) : t)
        .toList();

    state = state.copyWith(
      loadedFiles: updatedLoaded,
      tabs:        updatedTabs,
    );

    // Auto-save after 2s of inactivity
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () => saveFile(fileId));

    // AI autocomplete debounce 800ms
    _aiDebounceTimer?.cancel();
    _aiDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _triggerAiSuggestion(fileId, newContent);
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────

  Future<void> saveFile(String fileId) async {
    final file = state.loadedFiles[fileId];
    if (file == null || !file.isDirty) return;

    try {
      await _datasource.saveFile(file);

      final savedFile = file.copyWith(isDirty: false);
      final updatedLoaded = {...state.loadedFiles, fileId: savedFile};
      final updatedTabs = state.tabs
          .map((t) => t.fileId == fileId ? t.copyWith(isDirty: false) : t)
          .toList();

      state = state.copyWith(
        loadedFiles: updatedLoaded,
        tabs:        updatedTabs,
      );
    } catch (e) {
      state = state.copyWith(error: 'Save failed: $e');
    }
  }

  Future<void> saveActiveFile() async {
    if (state.activeTabId != null) {
      await saveFile(state.activeTabId!);
    }
  }

  // ── AI Autocomplete ───────────────────────────────────────────────────

  Future<void> _triggerAiSuggestion(String fileId, String content) async {
    if (content.isEmpty) return;
    final file = state.loadedFiles[fileId];
    if (file == null) return;
    try {
      final suggestion = await _datasource.getSuggestion(
        file.projectId,
        content,
        content.length,
      );
      if (suggestion != null && mounted) {
        state = state.copyWith(
          aiSuggestion:     suggestion,
          showAiSuggestion: true,
        );
      }
    } catch (_) {
      // Silent fail for suggestions
    }
  }

  void acceptAiSuggestion() {
    final suggestion = state.aiSuggestion;
    if (suggestion == null || state.activeTabId == null) return;

    final file = state.loadedFiles[state.activeTabId!];
    if (file == null) return;

    final newContent = file.content + suggestion;
    onContentChanged(state.activeTabId!, newContent);
    dismissAiSuggestion();
  }

  void dismissAiSuggestion() {
    state = state.copyWith(
      aiSuggestion:     null,
      showAiSuggestion: false,
    );
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Providers ─────────────────────────────────────────────────────────────

final editorRemoteDatasourceProvider = Provider<EditorRemoteDatasource>(
  (_) => EditorRemoteDatasourceImpl(),
);

final editorProvider =
    StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier(ref.read(editorRemoteDatasourceProvider));
});

// Convenience selectors
final activeFileProvider = Provider<CodeFile?>((ref) {
  return ref.watch(editorProvider).activeFile;
});

final openTabsProvider = Provider<List<EditorTab>>((ref) {
  return ref.watch(editorProvider).tabs;
});
