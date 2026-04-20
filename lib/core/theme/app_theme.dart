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

// ── Light Theme ───────────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
    headlineLarge: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColorsLight.textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColorsLight.textPrimary,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColorsLight.textPrimary,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColorsLight.textSecondary,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColorsLight.textOnAccent,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColorsLight.backgroundStart,
    colorScheme: ColorScheme.light(
      primary: AppColorsLight.primaryAccent,
      secondary: AppColorsLight.secondaryAccent,
      surface: AppColorsLight.backgroundStart,
      error: AppColorsLight.error,
    ),
    dividerColor: AppColorsLight.divider,
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsLight.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide: BorderSide(color: AppColorsLight.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide: BorderSide(color: AppColorsLight.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide:
            const BorderSide(color: AppColorsLight.primaryAccent, width: 1.5),
      ),
      hintStyle:
          GoogleFonts.poppins(color: AppColorsLight.textSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLight.primaryAccent,
        foregroundColor: AppColorsLight.textOnAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle:
            GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColorsLight.glassPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsLight.textPrimary,
      contentTextStyle: GoogleFonts.poppins(
        color: AppColorsLight.backgroundStart,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── Dark Theme ────────────────────────────────────────────────────────────────

ThemeData buildDarkAppTheme() {
  final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
    headlineLarge: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColorsDark.textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColorsDark.textPrimary,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColorsDark.textPrimary,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColorsDark.textPrimary,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColorsDark.textSecondary,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColorsDark.textOnAccent,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsDark.backgroundStart,
    colorScheme: ColorScheme.dark(
      primary: AppColorsDark.primaryAccent,
      secondary: AppColorsDark.secondaryAccent,
      surface: AppColorsDark.glassPanel,
      error: AppColorsDark.error,
    ),
    dividerColor: AppColorsDark.divider,
    cardColor: AppColorsDark.cardSurface,
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide: BorderSide(color: AppColorsDark.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide: BorderSide(color: AppColorsDark.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        borderSide:
            const BorderSide(color: AppColorsDark.primaryAccent, width: 1.5),
      ),
      hintStyle:
          GoogleFonts.poppins(color: AppColorsDark.textSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primaryAccent,
        foregroundColor: AppColorsDark.textOnAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle:
            GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColorsDark.glassPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorsDark.glassBorder),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColorsDark.glassPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColorsDark.glassPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsDark.textPrimary,
      contentTextStyle: GoogleFonts.poppins(
        color: AppColorsDark.backgroundStart,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
