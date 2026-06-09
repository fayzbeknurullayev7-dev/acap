import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/project.dart';

abstract class ProjectsRemoteDatasource {
  Future<List<Project>> fetchProjects();
  Future<Project> createProject({
    required String name,
    required String language,
    String description = '',
  });
  Future<void> deleteProject(String projectId);
}

class ProjectsRemoteDatasourceImpl implements ProjectsRemoteDatasource {
  final Dio _dio = DioClient.projects;

  @override
  Future<List<Project>> fetchProjects() async {
    try {
      final response = await _dio.get('/projects');
      final data = response.data;
      final list = (data is Map<String, dynamic> ? data['items'] : data)
          as List<dynamic>;
      return list
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  @override
  Future<Project> createProject({
    required String name,
    required String language,
    String description = '',
  }) async {
    try {
      final response = await _dio.post('/projects', data: {
        'name': name,
        'language': language,
        'description': description,
      });
      return Project.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    try {
      await _dio.delete('/projects/$projectId');
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }
}
