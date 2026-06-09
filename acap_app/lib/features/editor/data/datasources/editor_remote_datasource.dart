import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/code_file.dart';

abstract class EditorRemoteDatasource {
  /// [fileId] is the base64url-encoded relative path returned by files-service.
  Future<CodeFile> openFile(String fileId, String projectId);

  Future<void> saveFile(CodeFile file);

  /// Inline AI completion. Returns `null` on any failure (fails silently).
  Future<String?> getSuggestion(
    String projectId,
    String content,
    int cursorPos,
  );
}

class EditorRemoteDatasourceImpl implements EditorRemoteDatasource {
  final Dio _dio = DioClient.files;

  // ── Open ────────────────────────────────────────────────────────────────
  @override
  Future<CodeFile> openFile(String fileId, String projectId) async {
    try {
      // fileId = base64url(relativePath) → decode back to the real path.
      final filePath = utf8.decode(base64Url.decode(fileId));
      // GET /files/{projectId}/{filePath}
      final response = await _dio.get('/files/$projectId/$filePath');
      final data = response.data as Map<String, dynamic>;
      return _mapToCodeFile(data, fallbackId: fileId, fallbackProject: projectId);
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────
  @override
  Future<void> saveFile(CodeFile file) async {
    try {
      // PUT /files/{projectId}/{path}
      await _dio.put(
        '/files/${file.projectId}/${file.path}',
        data: {'content': file.content},
      );
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  // ── AI suggestion ─────────────────────────────────────────────────────────
  @override
  Future<String?> getSuggestion(
    String projectId,
    String content,
    int cursorPos,
  ) async {
    try {
      // POST /files/{projectId}/suggest
      final response = await _dio.post(
        '/files/$projectId/suggest',
        data: {
          'file_id': '',
          'content': content,
          'cursor_position': cursorPos,
        },
      );
      return response.data['suggestion'] as String?;
    } catch (_) {
      return null; // Suggestions never surface errors to the user.
    }
  }

  // ── Mapping ───────────────────────────────────────────────────────────────
  CodeFile _mapToCodeFile(
    Map<String, dynamic> data, {
    required String fallbackId,
    required String fallbackProject,
  }) {
    final path = (data['path'] as String?) ?? '';
    final name = (data['name'] as String?) ??
        (path.isNotEmpty ? path.split('/').last : '');
    final updatedRaw = data['updated_at'] as String?;
    return CodeFile(
      id:        (data['id'] as String?) ?? fallbackId,
      projectId: (data['project_id'] as String?) ?? fallbackProject,
      path:      path,
      name:      name,
      content:   (data['content'] as String?) ?? '',
      language:  _parseLanguage((data['language'] as String?) ?? ''),
      size:      (data['size'] as int?) ?? 0,
      updatedAt: updatedRaw != null
          ? (DateTime.tryParse(updatedRaw) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  FileLanguage _parseLanguage(String lang) {
    switch (lang.toLowerCase()) {
      case 'dart':       return FileLanguage.dart;
      case 'python':     return FileLanguage.python;
      case 'javascript': return FileLanguage.javascript;
      case 'typescript': return FileLanguage.typescript;
      case 'kotlin':     return FileLanguage.kotlin;
      case 'swift':      return FileLanguage.swift;
      case 'java':       return FileLanguage.java;
      case 'cpp':        return FileLanguage.cpp;
      case 'c':          return FileLanguage.c;
      case 'rust':       return FileLanguage.rust;
      case 'go':         return FileLanguage.go;
      case 'html':       return FileLanguage.html;
      case 'css':        return FileLanguage.css;
      case 'json':       return FileLanguage.json;
      case 'yaml':       return FileLanguage.yaml;
      case 'markdown':   return FileLanguage.markdown;
      case 'bash':       return FileLanguage.bash;
      case 'sql':        return FileLanguage.sql;
      case 'dockerfile': return FileLanguage.dockerfile;
      default:           return FileLanguage.plaintext;
    }
  }
}
