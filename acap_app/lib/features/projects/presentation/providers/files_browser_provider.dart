import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/file_info.dart';

/// Local provider — faqat ProjectDetailScreen'dagi file browser uchun.
/// files-service `GET /files/{project_id}` dan ro'yxatni oladi.
final filesProvider = StateProvider<List<FileInfo>>((_) => const []);

/// Yuklash holati (loading spinner uchun).
final filesLoadingProvider = StateProvider<bool>((_) => false);

/// Dio bilan GET /files/:id — fayl ro'yxatini qaytaradi.
Future<List<FileInfo>> fetchFiles(WidgetRef ref, String projectId) async {
  final dio = DioClient.files;
  ref.read(filesLoadingProvider.notifier).state = true;
  try {
    final response = await dio.get('/files/$projectId');
    final data = response.data;
    final raw = (data is Map<String, dynamic> ? data['files'] : data)
        as List<dynamic>? ??
        const [];
    final files = raw
        .map((e) => FileInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    ref.read(filesProvider.notifier).state = files;
    return files;
  } on DioException {
    ref.read(filesProvider.notifier).state = const [];
    return const [];
  } finally {
    ref.read(filesLoadingProvider.notifier).state = false;
  }
}
