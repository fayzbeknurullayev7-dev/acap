import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      context.go(AppRoutes.dashboard);
    } else {
      // Check if first launch (show onboarding)
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientBackground,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.terminal_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.6, 0.6)),

              const SizedBox(height: 24),

              // App name
              Text(
                'ACAP',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 42,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppColors.primary, AppColors.tertiary],
                    ).createShader(
                      const Rect.fromLTWH(0, 0, 200, 60),
                    ),
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              Text(
                'AI Coding Agent Platform',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 80),

              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ).animate(delay: 800.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
