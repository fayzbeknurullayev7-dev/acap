import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/projects/presentation/screens/projects_screen.dart';
import '../features/projects/presentation/screens/project_detail_screen.dart';
import '../features/agent/presentation/screens/agent_screen.dart';
import '../features/editor/presentation/screens/editor_screen.dart';
import '../features/terminal/presentation/screens/terminal_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

// Route names
class AppRoutes {
  static const splash      = '/splash';
  static const onboarding  = '/onboard';
  static const login       = '/login';
  static const otpVerify   = '/login/otp';
  static const dashboard   = '/dashboard';
  static const chat        = '/chat/:sessionId';
  static const projects    = '/projects';
  static const projectDetail = '/projects/:id';
  static const files       = '/projects/:id/files';
  static const editor      = '/editor/:fileId';
  static const terminal    = '/terminal/:sessionId';
  static const git         = '/projects/:id/git';
  static const deploy      = '/projects/:id/deploy';
  static const settings    = '/settings';
  static const profile     = '/profile';
  static const billing     = '/billing';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn  = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation == AppRoutes.onboarding ||
          state.matchedLocation == AppRoutes.splash;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute && state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.projects,
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: AppRoutes.projectDetail, // /projects/:id
        builder: (context, state) => ProjectDetailScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.chat, // /chat/:sessionId
        builder: (context, state) => AgentScreen(
          projectId: state.uri.queryParameters['projectId'] ?? '',
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.editor, // /editor/:fileId?projectId=
        builder: (context, state) => EditorScreen(
          fileId: state.pathParameters['fileId']!,
          projectId: state.uri.queryParameters['projectId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.terminal, // /terminal/:sessionId?projectId=
        builder: (context, state) => TerminalScreen(
          sessionId: state.pathParameters['sessionId']!,
          projectId: state.uri.queryParameters['projectId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
