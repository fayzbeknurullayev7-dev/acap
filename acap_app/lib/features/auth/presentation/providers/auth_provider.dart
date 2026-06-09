import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// ── Repository & UseCase providers ─────────────────────────────────────

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (_) => AuthRemoteDatasourceImpl(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDatasourceProvider));
});

final signInWithGoogleUseCaseProvider = Provider(
  (ref) => SignInWithGoogleUseCase(ref.read(authRepositoryProvider)),
);

final sendOtpUseCaseProvider = Provider(
  (ref) => SendOtpUseCase(ref.read(authRepositoryProvider)),
);

final verifyOtpUseCaseProvider = Provider(
  (ref) => VerifyOtpUseCase(ref.read(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider(
  (ref) => LogoutUseCase(ref.read(authRepositoryProvider)),
);

// ── Auth State ──────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user:            user            ?? this.user,
      isLoading:       isLoading       ?? this.isLoading,
      error:           error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ── Auth Notifier ───────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SignInWithGoogleUseCase _googleSignIn;
  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;
  final LogoutUseCase _logout;

  AuthNotifier({
    required AuthRepository repository,
    required SignInWithGoogleUseCase googleSignIn,
    required SendOtpUseCase sendOtp,
    required VerifyOtpUseCase verifyOtp,
    required LogoutUseCase logout,
  })  : _repository = repository,
        _googleSignIn = googleSignIn,
        _sendOtp = sendOtp,
        _verifyOtp = verifyOtp,
        _logout = logout,
        super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await _repository.isAuthenticated();
    if (isAuth) {
      final result = await _repository.getCurrentUser();
      result.fold(
        (_) => state = const AuthState(isAuthenticated: false),
        (user) => state = AuthState(user: user, isAuthenticated: true),
      );
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    final result = await _googleSignIn();
    if (result.isRight()) {
      await _checkAuthStatus();
      return true;
    }
    final failure = result.fold((l) => l, (_) => null);
    state = state.copyWith(isLoading: false, error: failure?.message);
    return false;
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true);
    final result = await _sendOtp(email);
    state = state.copyWith(isLoading: false);
    return result.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true);
    final result = await _verifyOtp(email, otp);
    if (result.isRight()) {
      await _checkAuthStatus();
      return true;
    }
    final failure = result.fold((l) => l, (_) => null);
    state = state.copyWith(isLoading: false, error: failure?.message);
    return false;
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _logout();
    state = const AuthState(isAuthenticated: false);
  }

  void clearError() => state = state.copyWith(error: null);
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository:  ref.read(authRepositoryProvider),
    googleSignIn: ref.read(signInWithGoogleUseCaseProvider),
    sendOtp:     ref.read(sendOtpUseCaseProvider),
    verifyOtp:   ref.read(verifyOtpUseCaseProvider),
    logout:      ref.read(logoutUseCaseProvider),
  );
});
