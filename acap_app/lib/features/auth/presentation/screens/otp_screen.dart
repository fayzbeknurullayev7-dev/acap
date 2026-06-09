import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController();
  int _remainingSeconds = AppConstants.otpTtlSec;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remainingSeconds = AppConstants.otpTtlSec);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  Future<void> _resendOtp() async {
    await ref.read(authStateProvider.notifier).sendOtp(widget.email);
    _startTimer();
  }

  Future<void> _verifyOtp(String otp) async {
    final success = await ref
        .read(authStateProvider.notifier)
        .verifyOtp(widget.email, otp);
    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  String get _timerText {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: AppTypography.titleLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text('Check your email', style: AppTypography.headlineMedium)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.1, end: 0),

            const SizedBox(height: 12),

            RichText(
              text: TextSpan(
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to\n'),
                  TextSpan(
                    text: widget.email,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 48),

            // PIN input
            Center(
              child: Pinput(
                controller: _pinController,
                length: AppConstants.otpLength,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                errorPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.error),
                  ),
                ),
                onCompleted: _verifyOtp,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            // Loading indicator
            if (authState.isLoading)
              const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),

            // Error
            if (authState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  authState.error!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),

            // Resend
            Center(
              child: _remainingSeconds > 0
                  ? Text(
                      'Resend code in $_timerText',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : TextButton(
                      onPressed: _resendOtp,
                      child: const Text('Resend code'),
                    ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
