import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Google OAuth sign-in
  Future<Either<Failure, AuthTokens>> signInWithGoogle();

  /// Send OTP to email
  Future<Either<Failure, void>> sendOtp(String email);

  /// Verify OTP and get tokens
  Future<Either<Failure, AuthTokens>> verifyOtp(String email, String otp);

  /// Refresh access token
  Future<Either<Failure, AuthTokens>> refreshToken(String refreshToken);

  /// Get current user profile
  Future<Either<Failure, User>> getCurrentUser();

  /// Logout
  Future<Either<Failure, void>> logout();

  /// Check if user is authenticated (local check)
  Future<bool> isAuthenticated();
}
