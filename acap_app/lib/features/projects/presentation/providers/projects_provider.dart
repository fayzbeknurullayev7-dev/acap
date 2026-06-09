import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/projects_remote_datasource.dart';
import '../../domain/entities/project.dart';

// ── State ─────────────────────────────────────────────────────────────────

class ProjectsState {
  final List<Project> projects;
  final bool isLoading;
  final String? error;

  const ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
  });

  /// Most recent projects first (by last activity).
  List<Project> get recent {
    final sorted = [...projects]
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return sorted;
  }

  ProjectsState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? error,
  }) {
    return ProjectsState(
      projects:  projects  ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error:     error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final ProjectsRemoteDatasource _datasource;

  ProjectsNotifier(this._datasource) : super(const ProjectsState()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final projects = await _datasource.fetchProjects();
      state = state.copyWith(projects: projects, isLoading: false);
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, error: f.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Project?> createProject({
    required String name,
    required String language,
    String description = '',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final project = await _datasource.createProject(
        name: name,
        language: language,
        description: description,
      );
      state = state.copyWith(
        projects: [project, ...state.projects],
        isLoading: false,
      );
      return project;
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, error: f.message);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> deleteProject(String projectId) async {
    final previous = state.projects;
    // Optimistic removal
    state = state.copyWith(
      projects: previous.where((p) => p.projectId != projectId).toList(),
    );
    try {
      await _datasource.deleteProject(projectId);
    } on Failure catch (f) {
      state = state.copyWith(projects: previous, error: f.message);
    } catch (e) {
      state = state.copyWith(projects: previous, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Providers ─────────────────────────────────────────────────────────────

final projectsRemoteDatasourceProvider =
    Provider<ProjectsRemoteDatasource>((_) => ProjectsRemoteDatasourceImpl());

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  return ProjectsNotifier(ref.read(projectsRemoteDatasourceProvider));
});
