import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Design-token constants shared across the app.
abstract final class AppTokens {
  static const double radiusPanel = 24.0;
  static const double radiusInput = 16.0;
  static const double radiusButton = 16.0;

  static const EdgeInsets paddingCard =
      EdgeInsets.symmetric(horizontal: 28, vertical: 32);

  static const double blurSigma = 10.0;

  /// Neo-morphism double shadow for interactive elements.
  static List<BoxShadow> get neoShadows => const [
        BoxShadow(
          color: Color(0x22000000),
          offset: Offset(4, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Color(0x44FFFFFF),
          offset: Offset(-4, -4),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get neoShadowsPressed => const [
        BoxShadow(
          color: Color(0x18000000),
          offset: Offset(2, 2),
          blurRadius: 6,
        ),
        BoxShadow(
          color: Color(0x30FFFFFF),
          offset: Offset(-2, -2),
          blurRadius: 6,
        ),
      ];
}

/// Builds the light-mode [ThemeData] for OfficeFlow.
ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
    headlineLarge: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textOnAccent,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundStart,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryAccent,
      secondary: AppColors.secondaryAccent,
      surface: AppColors.backgroundStart,
      error: AppColors.error,
    ),
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
      ),
      hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.textOnAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
