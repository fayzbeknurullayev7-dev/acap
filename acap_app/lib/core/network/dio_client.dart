import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';
import '../errors/failures.dart';
import '../storage/hive_service.dart';

final _logger = Logger();

class DioClient {
  static Dio? _instance;
  static const _storage = FlutterSecureStorage();

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  // ── Per-service clients ───────────────────────────────────────────────
  // auth keeps the legacy client (base already includes /api/v1).
  static Dio get auth     => instance;
  static Dio get projects => _serviceClient(AppConstants.projectsUrl);
  static Dio get files    => _serviceClient(AppConstants.filesUrl);
  static Dio get terminal => _serviceClient(AppConstants.terminalUrl);
  static Dio get agent    => _serviceClient(AppConstants.agentUrl);

  static Dio _serviceClient(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await HiveService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            final token = await HiveService.getAccessToken();
            opts.headers['Authorization'] = 'Bearer $token';
            final response = await Dio().fetch(opts);
            handler.resolve(response);
            return;
          }
        }
        handler.next(error);
      },
    ));
    return dio;
  }

  // Refresh via the auth service (legacy client already targets /api/v1).
  static Future<bool> _tryRefreshToken() async {
    try {
      final refresh = await HiveService.getRefreshToken();
      if (refresh == null) return false;
      final res = await instance.post(
        '/auth/token/refresh',
        data: {'refresh_token': refresh},
        options: Options(headers: {'Authorization': null}),
      );
      final newToken = res.data['access_token'] as String;
      await HiveService.setAccessToken(newToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        sendTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(_storage, dio),
      _LoggingInterceptor(),
    ]);

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;

  _AuthInterceptor(this.storage, this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read(key: AppConstants.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        final refreshToken = await storage.read(
          key: AppConstants.refreshToken,
        );
        if (refreshToken == null) {
          await _clearTokens();
          handler.next(err);
          return;
        }

        final response = await dio.post(
          '/auth/token/refresh',
          data: {'refresh_token': refreshToken},
          options: Options(
            headers: {'Authorization': null},
          ),
        );

        final newToken = response.data['access_token'] as String;
        await storage.write(
          key: AppConstants.accessToken,
          value: newToken,
        );

        // Retry original request
        final retryResponse = await dio.fetch(
          err.requestOptions..headers['Authorization'] = 'Bearer $newToken',
        );
        handler.resolve(retryResponse);
      } catch (_) {
        await _clearTokens();
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const UnauthorizedFailure(),
          ),
        );
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: AppConstants.accessToken);
    await storage.delete(key: AppConstants.refreshToken);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('[REQ] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('[RES] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('[ERR] ${err.response?.statusCode} ${err.message}');
    handler.next(err);
  }
}

// Map DioException to Failure
Failure dioToFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      final msg  = e.response?.data?['detail'] as String? ?? 'Server error';
      if (code == 401) return UnauthorizedFailure(msg);
      if (code == 404) return NotFoundFailure(msg);
      if (code == 422) return ValidationFailure(msg);
      return ServerFailure(msg, statusCode: code);
    default:
      if (e.error is UnauthorizedFailure) return e.error as UnauthorizedFailure;
      return const UnknownFailure();
  }
}
