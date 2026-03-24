import 'package:flutter/material.dart';

/// OfficeFlow Premium color palette – Glass-Neo-Minimalism
abstract final class AppColors {
  // ── Background Gradient ──
  static const Color backgroundStart = Color(0xFFFBFBFC);
  static const Color backgroundEnd = Color(0xFFFFFFFF);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );

  // ── Accent ──
  static const Color primaryAccent = Color(0xFF00C4CC); // Electric Teal
  static const Color secondaryAccent = Color(0xFFE0A9A5); // Soft Rose Gold

  // ── Glass ──
  static const Color glassPanel = Color(0x66FFFFFF); // 40 % white
  static const Color glassBorder = Color(0x33FFFFFF); // 20 % white
  static const Color glassShadow = Color(0x1A000000); // 10 % black

  // ── Text ──
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Status ──
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);

  // ── Input ──
  static const Color inputFill = Color(0x1A000000); // 10 % black "carved" look
  static const Color inputBorder = Color(0x22000000);
}
