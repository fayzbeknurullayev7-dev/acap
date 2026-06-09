import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  static const displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const code = TextStyle(
    fontSize: 14,
    fontFamily: 'JetBrainsMono',
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const codeSmall = TextStyle(
    fontSize: 12,
    fontFamily: 'JetBrainsMono',
    color: AppColors.textSecondary,
    height: 1.5,
  );
}
