import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary    = Color(0xFF6366F1); // Indigo 500
  static const secondary  = Color(0xFF8B5CF6); // Violet 500
  static const tertiary   = Color(0xFF06B6D4); // Cyan 500

  // Surfaces
  static const background = Color(0xFF0F0F11);
  static const surface    = Color(0xFF18181B); // Zinc 900
  static const surfaceVar = Color(0xFF27272A); // Zinc 800
  static const outline    = Color(0xFF3F3F46); // Zinc 700
  static const border     = outline;           // card / input border alias

  // Semantic
  static const error      = Color(0xFFEF4444); // Red 500
  static const success    = Color(0xFF22C55E); // Green 500
  static const warning    = Color(0xFFF59E0B); // Amber 500
  static const info       = Color(0xFF3B82F6); // Blue 500

  // Text
  static const textPrimary   = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const textDisabled  = Color(0xFF52525B); // Zinc 600

  // Code syntax
  static const codeKeyword  = Color(0xFFC792EA);
  static const codeString   = Color(0xFFC3E88D);
  static const codeComment  = Color(0xFF546E7A);
  static const codeNumber   = Color(0xFFF78C6C);
  static const codeFunction = Color(0xFF82AAFF);
  static const codeType     = Color(0xFFFFCB6B);

  // Gradients
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), background],
  );
}
