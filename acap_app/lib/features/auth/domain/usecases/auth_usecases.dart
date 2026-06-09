import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository repository;
  const SignInWithGoogleUseCase(this.repository);

  Future<Either<Failure, AuthTokens>> call() =>
      repository.signInWithGoogle();
}

class SendOtpUseCase {
  final AuthRepository repository;
  const SendOtpUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) =>
      repository.sendOtp(email);
}

class VerifyOtpUseCase {
  final AuthRepository repository;
  const VerifyOtpUseCase(this.repository);

  Future<Either<Failure, AuthTokens>> call(String email, String otp) =>
      repository.verifyOtp(email, otp);
}

class GetCurrentUserUseCase {
  final AuthRepository repository;
  const GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, User>> call() =>
      repository.getCurrentUser();
}

class LogoutUseCase {
  final AuthRepository repository;
  const LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() =>
      repository.logout();
}
