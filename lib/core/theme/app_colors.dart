import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🎨  PALETA DE COLORES — PulseOffice (Light + Dark)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Sistema de dos paletas: [AppColorsLight] y [AppColorsDark], exponiendo
/// cada valor a través de la clase de acceso [AppColors], que delega al
/// tema activo en contexto usando extension methods sobre [BuildContext].
/// ═══════════════════════════════════════════════════════════════════════════

// ── Paleta Light ─────────────────────────────────────────────────────────────

abstract final class AppColorsLight {
  // Fondos
  static const Color backgroundStart = Color(0xFFF8FAFC);
  static const Color backgroundEnd   = Color(0xFFFFFFFF);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );

  // Acento principal (Indigo 600)
  static const Color primaryAccent   = Color(0xFF4F46E5);
  static const Color secondaryAccent = Color(0xFF818CF8);

  // Tarjetas
  static const Color glassPanel  = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0x00FFFFFF);
  static const Color glassShadow = Color(0x00000000);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Texto
  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnAccent  = Color(0xFFFFFFFF);
  static const Color textDisabled  = Color(0xFFCBD5E1);

  // Estado
  static const Color success = Color(0xFF10B981);
  static const Color error   = Color(0xFFF43F5E);

  // Inputs
  static const Color inputFill   = Color(0x0F000000);
  static const Color inputBorder = Color(0x1A000000);

  // FAB
  static const Color fabGradientStart = Color(0xFF4F46E5);
  static const Color fabGradientEnd   = Color(0xFF4338CA);

  // Separadores
  static const Color divider = Color(0xFFE2E8F0);

  // Calendario
  static const Color calendarSurface = Color(0xFFFFFFFF);
  static const Color calendarDayFuture = Color(0xFFCBD5E1);

  // Status Hero Card
  static const Color statusActiveStart = Color(0xFF10B981);
  static const Color statusActiveEnd   = Color(0xFF059669);
  static const Color statusInactiveStart = Color(0xFF6366F1);
  static const Color statusInactiveEnd   = Color(0xFF4F46E5);

  // Shimmer / Skeleton
  static const Color shimmerBase      = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);

  // Timeline
  static const Color timelineLine     = Color(0xFFE2E8F0);
  static const Color timelineDot      = Color(0xFF4F46E5);
}

// ── Paleta Dark ───────────────────────────────────────────────────────────────

abstract final class AppColorsDark {
  // Fondos estratificados — tres capas de oscuro, evitando negro puro
  static const Color backgroundStart = Color(0xFF0F1117); // Fondo base profundo
  static const Color backgroundEnd   = Color(0xFF0F1117);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );

  // Mismos acentos: el Indigo funciona perfectamente en dark mode
  static const Color primaryAccent   = Color(0xFF6366F1); // Indigo 500 (un poco más claro en dark)
  static const Color secondaryAccent = Color(0xFF818CF8);

  // Tarjetas (elevación oscura estratificada)
  static const Color glassPanel  = Color(0xFF1E2130);  // Superficie elevada
  static const Color glassBorder = Color(0xFF2D3348);
  static const Color glassShadow = Color(0x44000000);
  static const Color cardSurface = Color(0xFF1E2130);

  // Texto
  static const Color textPrimary   = Color(0xFFF1F5F9);  // Slate casi blanco
  static const Color textSecondary = Color(0xFF94A3B8);  // Slate gris suave
  static const Color textOnAccent  = Color(0xFFFFFFFF);
  static const Color textDisabled  = Color(0xFF334155);

  // Estado (mismo tono, perfectamente visible en dark)
  static const Color success = Color(0xFF10B981);
  static const Color error   = Color(0xFFF43F5E);

  // Inputs
  static const Color inputFill   = Color(0xFF1E2130);
  static const Color inputBorder = Color(0xFF2D3348);

  // FAB (ligeramente más brillante en dark para contraste)
  static const Color fabGradientStart = Color(0xFF6366F1);
  static const Color fabGradientEnd   = Color(0xFF4F46E5);

  // Separadores
  static const Color divider = Color(0xFF1E293B);

  // Calendario
  static const Color calendarSurface  = Color(0xFF1E2130);
  static const Color calendarDayFuture = Color(0xFF2D3348);

  // Status Hero Card
  static const Color statusActiveStart = Color(0xFF10B981);
  static const Color statusActiveEnd   = Color(0xFF047857);
  static const Color statusInactiveStart = Color(0xFF818CF8);
  static const Color statusInactiveEnd   = Color(0xFF6366F1);

  // Shimmer / Skeleton
  static const Color shimmerBase      = Color(0xFF1E2130);
  static const Color shimmerHighlight = Color(0xFF2D3348);

  // Timeline
  static const Color timelineLine     = Color(0xFF2D3348);
  static const Color timelineDot      = Color(0xFF818CF8);
}

// ── Acceso Unificado via BuildContext ─────────────────────────────────────────

/// Proporciona los tokens de color correctos según el tema activo.
/// Uso: `context.colors.primaryAccent`
extension AppColorsX on BuildContext {
  _AppColorTokens get colors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const _DarkTokens() : const _LightTokens();
  }
}

abstract interface class _AppColorTokens {
  Color get backgroundStart;
  LinearGradient get backgroundGradient;
  Color get primaryAccent;
  Color get secondaryAccent;
  Color get glassPanel;
  Color get glassBorder;
  Color get glassShadow;
  Color get cardSurface;
  Color get textPrimary;
  Color get textSecondary;
  Color get textOnAccent;
  Color get textDisabled;
  Color get success;
  Color get error;
  Color get inputFill;
  Color get inputBorder;
  Color get fabGradientStart;
  Color get fabGradientEnd;
  Color get divider;
  Color get calendarSurface;
  Color get calendarDayFuture;
  Color get statusActiveStart;
  Color get statusActiveEnd;
  Color get statusInactiveStart;
  Color get statusInactiveEnd;
  Color get shimmerBase;
  Color get shimmerHighlight;
  Color get timelineLine;
  Color get timelineDot;
}

class _LightTokens implements _AppColorTokens {
  const _LightTokens();
  @override Color get backgroundStart       => AppColorsLight.backgroundStart;
  @override LinearGradient get backgroundGradient => AppColorsLight.backgroundGradient;
  @override Color get primaryAccent         => AppColorsLight.primaryAccent;
  @override Color get secondaryAccent       => AppColorsLight.secondaryAccent;
  @override Color get glassPanel            => AppColorsLight.glassPanel;
  @override Color get glassBorder           => AppColorsLight.glassBorder;
  @override Color get glassShadow           => AppColorsLight.glassShadow;
  @override Color get cardSurface           => AppColorsLight.cardSurface;
  @override Color get textPrimary           => AppColorsLight.textPrimary;
  @override Color get textSecondary         => AppColorsLight.textSecondary;
  @override Color get textOnAccent          => AppColorsLight.textOnAccent;
  @override Color get textDisabled          => AppColorsLight.textDisabled;
  @override Color get success               => AppColorsLight.success;
  @override Color get error                 => AppColorsLight.error;
  @override Color get inputFill             => AppColorsLight.inputFill;
  @override Color get inputBorder           => AppColorsLight.inputBorder;
  @override Color get fabGradientStart      => AppColorsLight.fabGradientStart;
  @override Color get fabGradientEnd        => AppColorsLight.fabGradientEnd;
  @override Color get divider               => AppColorsLight.divider;
  @override Color get calendarSurface       => AppColorsLight.calendarSurface;
  @override Color get calendarDayFuture     => AppColorsLight.calendarDayFuture;
  @override Color get statusActiveStart     => AppColorsLight.statusActiveStart;
  @override Color get statusActiveEnd       => AppColorsLight.statusActiveEnd;
  @override Color get statusInactiveStart   => AppColorsLight.statusInactiveStart;
  @override Color get statusInactiveEnd     => AppColorsLight.statusInactiveEnd;
  @override Color get shimmerBase           => AppColorsLight.shimmerBase;
  @override Color get shimmerHighlight      => AppColorsLight.shimmerHighlight;
  @override Color get timelineLine          => AppColorsLight.timelineLine;
  @override Color get timelineDot           => AppColorsLight.timelineDot;
}

class _DarkTokens implements _AppColorTokens {
  const _DarkTokens();
  @override Color get backgroundStart       => AppColorsDark.backgroundStart;
  @override LinearGradient get backgroundGradient => AppColorsDark.backgroundGradient;
  @override Color get primaryAccent         => AppColorsDark.primaryAccent;
  @override Color get secondaryAccent       => AppColorsDark.secondaryAccent;
  @override Color get glassPanel            => AppColorsDark.glassPanel;
  @override Color get glassBorder           => AppColorsDark.glassBorder;
  @override Color get glassShadow           => AppColorsDark.glassShadow;
  @override Color get cardSurface           => AppColorsDark.cardSurface;
  @override Color get textPrimary           => AppColorsDark.textPrimary;
  @override Color get textSecondary         => AppColorsDark.textSecondary;
  @override Color get textOnAccent          => AppColorsDark.textOnAccent;
  @override Color get textDisabled          => AppColorsDark.textDisabled;
  @override Color get success               => AppColorsDark.success;
  @override Color get error                 => AppColorsDark.error;
  @override Color get inputFill             => AppColorsDark.inputFill;
  @override Color get inputBorder           => AppColorsDark.inputBorder;
  @override Color get fabGradientStart      => AppColorsDark.fabGradientStart;
  @override Color get fabGradientEnd        => AppColorsDark.fabGradientEnd;
  @override Color get divider               => AppColorsDark.divider;
  @override Color get calendarSurface       => AppColorsDark.calendarSurface;
  @override Color get calendarDayFuture     => AppColorsDark.calendarDayFuture;
  @override Color get statusActiveStart     => AppColorsDark.statusActiveStart;
  @override Color get statusActiveEnd       => AppColorsDark.statusActiveEnd;
  @override Color get statusInactiveStart   => AppColorsDark.statusInactiveStart;
  @override Color get statusInactiveEnd     => AppColorsDark.statusInactiveEnd;
  @override Color get shimmerBase           => AppColorsDark.shimmerBase;
  @override Color get shimmerHighlight      => AppColorsDark.shimmerHighlight;
  @override Color get timelineLine          => AppColorsDark.timelineLine;
  @override Color get timelineDot           => AppColorsDark.timelineDot;
}

// ── Backward compatibility aliases ────────────────────────────────────────────
/// Alias estático para pantallas que aún usan AppColors.X directamente.
/// Apunta a la paleta light. Las pantallas con soporte dark deben migrar
/// a `context.colors.X`.
abstract final class AppColors {
  static const Color backgroundStart = AppColorsLight.backgroundStart;
  static const Color backgroundEnd   = AppColorsLight.backgroundEnd;
  static const LinearGradient backgroundGradient = AppColorsLight.backgroundGradient;
  static const Color primaryAccent   = AppColorsLight.primaryAccent;
  static const Color secondaryAccent = AppColorsLight.secondaryAccent;
  static const Color glassPanel      = AppColorsLight.glassPanel;
  static const Color glassBorder     = AppColorsLight.glassBorder;
  static const Color glassShadow     = AppColorsLight.glassShadow;
  static const Color textPrimary     = AppColorsLight.textPrimary;
  static const Color textSecondary   = AppColorsLight.textSecondary;
  static const Color textOnAccent    = AppColorsLight.textOnAccent;
  static const Color success         = AppColorsLight.success;
  static const Color error           = AppColorsLight.error;
  static const Color inputFill       = AppColorsLight.inputFill;
  static const Color inputBorder     = AppColorsLight.inputBorder;
  static const Color fabGradientStart = AppColorsLight.fabGradientStart;
  static const Color fabGradientEnd   = AppColorsLight.fabGradientEnd;
  static const Color successCircleBg  = AppColorsLight.success;
  static const Color successIcon      = AppColorsLight.textOnAccent;
  static const Color errorCircleBg    = AppColorsLight.error;
  static const Color errorIcon        = AppColorsLight.textOnAccent;
}
