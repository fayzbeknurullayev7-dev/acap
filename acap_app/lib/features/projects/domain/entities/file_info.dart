import 'package:equatable/equatable.dart';

/// files-service `GET /files/{project_id}` javobidagi bitta fayl.
class FileInfo extends Equatable {
  final String id; // path ni base64 ko'rinishi (editor route uchun)
  final String name;
  final String path; // project root'dan relative
  final String language;
  final int size;
  final DateTime updatedAt;

  const FileInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.language,
    required this.size,
    required this.updatedAt,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    DateTime parse(String? v) =>
        v == null ? DateTime.now() : (DateTime.tryParse(v) ?? DateTime.now());
    return FileInfo(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      path: (json['path'] ?? '') as String,
      language: (json['language'] ?? 'plaintext') as String,
      size: (json['size'] ?? 0) as int,
      updatedAt: parse(json['updated_at'] as String?),
    );
  }

  @override
  List<Object?> get props => [id, path, size, updatedAt];
}
