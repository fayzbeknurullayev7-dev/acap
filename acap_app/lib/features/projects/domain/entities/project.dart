import 'package:equatable/equatable.dart';

/// Plain project entity (no freezed — matches the project-wide style).
class Project extends Equatable {
  final String projectId;
  final String name;
  final String description;
  final String language;
  final DateTime createdAt;
  final DateTime lastActivity;

  const Project({
    required this.projectId,
    required this.name,
    required this.description,
    required this.language,
    required this.createdAt,
    required this.lastActivity,
  });

  Project copyWith({
    String? name,
    String? description,
    String? language,
    DateTime? lastActivity,
  }) {
    return Project(
      projectId:    projectId,
      name:         name         ?? this.name,
      description:  description  ?? this.description,
      language:     language     ?? this.language,
      createdAt:    createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    DateTime parse(String? v) =>
        v == null ? DateTime.now() : DateTime.parse(v);
    return Project(
      projectId:    (json['id'] ?? json['project_id'] ?? '') as String,
      name:         (json['name'] ?? '') as String,
      description:  (json['description'] ?? '') as String,
      language:     (json['language'] ?? 'plaintext') as String,
      createdAt:    parse(json['created_at'] as String?),
      lastActivity: parse(
        (json['last_activity'] ?? json['updated_at']) as String?,
      ),
    );
  }

  @override
  List<Object?> get props => [projectId, name, language, lastActivity];
}
