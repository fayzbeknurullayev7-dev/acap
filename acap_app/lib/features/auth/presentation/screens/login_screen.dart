import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authStateProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  Future<void> _handleEmailContinue() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final success = await ref.read(authStateProvider.notifier).sendOtp(email);
    if (success && mounted) {
      context.push(AppRoutes.otpVerify, extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Logo + Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.terminal_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Welcome to ACAP', style: AppTypography.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Your AI coding agent, everywhere.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 56),

                  // Google Sign-In
                  GoogleSignInButton(
                    onPressed: _handleGoogleSignIn,
                    isLoading: authState.isLoading,
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with email',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.outline)),
                    ],
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppColors.textSecondary),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 16),

                  // Email continue button
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleEmailContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVar,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Continue with Email'),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 400.ms),

                  // Error message
                  if (authState.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Terms
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      style: AppTypography.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
