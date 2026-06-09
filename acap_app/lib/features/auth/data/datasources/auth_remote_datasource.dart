import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDatasource {
  Future<AuthTokensModel> signInWithGoogle();
  Future<void> sendOtp(String email);
  Future<AuthTokensModel> verifyOtp(String email, String otp);
  Future<AuthTokensModel> refreshToken(String refreshToken);
  Future<UserModel> getCurrentUser();
  Future<void> logout();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final Dio _dio = DioClient.auth;
  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  Future<AuthTokensModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthFailure('Google sign-in cancelled');

      final googleAuth = await googleUser.authentication;
      final idToken    = googleAuth.idToken;
      if (idToken == null) throw const AuthFailure('Failed to get Google token');

      final response = await _dio.post(
        '/auth/google/token',
        data: {'id_token': idToken},
      );

      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      await _dio.post('/auth/otp/send', data: {'email': email});
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  @override
  Future<AuthTokensModel> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/otp/verify',
        data: {'email': email, 'otp': otp},
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  @override
  Future<AuthTokensModel> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/token/refresh',
        data: {'refresh_token': refreshToken},
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
      await _googleSignIn.signOut();
      await _storage.delete(key: AppConstants.accessToken);
      await _storage.delete(key: AppConstants.refreshToken);
    } on DioException catch (e) {
      throw dioToFailure(e);
    }
  }
}
