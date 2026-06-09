import 'package:equatable/equatable.dart';

enum FileLanguage {
  dart, python, javascript, typescript, kotlin, swift,
  java, cpp, c, rust, go, html, css, json, yaml,
  markdown, bash, sql, dockerfile, plaintext;

  static FileLanguage fromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'dart':        return dart;
      case 'py':          return python;
      case 'js':          return javascript;
      case 'ts':          return typescript;
      case 'kt':          return kotlin;
      case 'swift':       return swift;
      case 'java':        return java;
      case 'cpp': case 'cc': case 'cxx': return cpp;
      case 'c':           return c;
      case 'rs':          return rust;
      case 'go':          return go;
      case 'html': case 'htm': return html;
      case 'css': case 'scss': return css;
      case 'json':        return json;
      case 'yaml': case 'yml': return yaml;
      case 'md':          return markdown;
      case 'sh': case 'bash': return bash;
      case 'sql':         return sql;
      case 'dockerfile':  return dockerfile;
      default:            return plaintext;
    }
  }

  String get displayName {
    switch (this) {
      case dart:        return 'Dart';
      case python:      return 'Python';
      case javascript:  return 'JavaScript';
      case typescript:  return 'TypeScript';
      case kotlin:      return 'Kotlin';
      case swift:       return 'Swift';
      case java:        return 'Java';
      case cpp:         return 'C++';
      case c:           return 'C';
      case rust:        return 'Rust';
      case go:          return 'Go';
      case html:        return 'HTML';
      case css:         return 'CSS';
      case json:        return 'JSON';
      case yaml:        return 'YAML';
      case markdown:    return 'Markdown';
      case bash:        return 'Bash';
      case sql:         return 'SQL';
      case dockerfile:  return 'Dockerfile';
      case plaintext:   return 'Text';
    }
  }
}

class CodeFile extends Equatable {
  final String id;
  final String projectId;
  final String path;        // e.g. "lib/main.dart"
  final String name;        // e.g. "main.dart"
  final String content;
  final FileLanguage language;
  final int size;
  final DateTime updatedAt;
  final bool isDirty;       // unsaved local changes

  const CodeFile({
    required this.id,
    required this.projectId,
    required this.path,
    required this.name,
    required this.content,
    required this.language,
    required this.size,
    required this.updatedAt,
    this.isDirty = false,
  });

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  CodeFile copyWith({
    String? content,
    bool? isDirty,
    DateTime? updatedAt,
  }) {
    return CodeFile(
      id:        id,
      projectId: projectId,
      path:      path,
      name:      name,
      content:   content   ?? this.content,
      language:  language,
      size:      size,
      updatedAt: updatedAt ?? this.updatedAt,
      isDirty:   isDirty   ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [id, path, content, isDirty];
}

class EditorTab extends Equatable {
  final String fileId;
  final String path;
  final String name;
  final bool isDirty;
  final FileLanguage language;

  const EditorTab({
    required this.fileId,
    required this.path,
    required this.name,
    this.isDirty = false,
    required this.language,
  });

  EditorTab copyWith({bool? isDirty}) =>
      EditorTab(
        fileId:   fileId,
        path:     path,
        name:     name,
        isDirty:  isDirty ?? this.isDirty,
        language: language,
      );

  @override
  List<Object?> get props => [fileId, isDirty];
}
