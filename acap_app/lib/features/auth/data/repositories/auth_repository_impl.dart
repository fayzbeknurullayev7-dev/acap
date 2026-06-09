import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final _storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, AuthTokens>> signInWithGoogle() async {
    try {
      final tokens = await _remote.signInWithGoogle();
      await _saveTokens(tokens.accessToken, tokens.refreshToken);
      return Right(tokens);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendOtp(String email) async {
    try {
      await _remote.sendOtp(email);
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> verifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final tokens = await _remote.verifyOtp(email, otp);
      await _saveTokens(tokens.accessToken, tokens.refreshToken);
      return Right(tokens);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final tokens = await _remote.refreshToken(refreshToken);
      await _saveTokens(tokens.accessToken, tokens.refreshToken);
      return Right(tokens);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await _remote.getCurrentUser();
      return Right(user);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: AppConstants.accessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: AppConstants.accessToken, value: access);
    await _storage.write(key: AppConstants.refreshToken, value: refresh);
  }
}
