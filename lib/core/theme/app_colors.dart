import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🎨  PALETA DE COLORES — Pulse App
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Para cambiar un color, solo modifica el valor hexadecimal.
/// Formato: Color(0xAARRGGBB)
///   AA = opacidad (FF = 100%, 80 = 50%, 00 = 0%)
///   RR = rojo,  GG = verde,  BB = azul
///
/// Ejemplo: Color(0xFF00C4CC)
///            ↑↑  ↑↑↑↑↑↑
///         opaco  color teal
///
/// Herramientas para elegir colores:
///   • https://colorhunt.co
///   • https://coolors.co
///   • https://www.color-hex.com
/// ═══════════════════════════════════════════════════════════════════════════
abstract final class AppColors {

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  FONDO DE LA APP (gradiente de esquina a esquina)                      │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color backgroundStart = Color(0xFFFBFBFC);  // Gris casi blanco
  static const Color backgroundEnd   = Color(0xFFFFFFFF);   // Blanco puro

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  COLORES PRINCIPALES (botones, FAB, chips activos, avatares)           │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color primaryAccent   = Color(0xFF00C4CC);   // Teal eléctrico
  static const Color secondaryAccent = Color(0xFFE0A9A5);   // Rosa-dorado suave

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  CRISTAL / GLASS (paneles translúcidos)                                │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color glassPanel  = Color(0x66FFFFFF);       // 40% blanco
  static const Color glassBorder = Color(0x33FFFFFF);       // 20% blanco
  static const Color glassShadow = Color(0x1A000000);       // 10% negro

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  TEXTO                                                                 │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color textPrimary   = Color(0xFF1A1A1A);     // Negro suave
  static const Color textSecondary = Color(0xFF757575);     // Gris medio
  static const Color textOnAccent  = Color(0xFFFFFFFF);     // Blanco (sobre botones)

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  ESTADO — Éxito / Error (check verde, X roja, alertas)                 │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color success = Color(0xFF4CAF50);           // Verde Material
  static const Color error   = Color(0xFFE53935);           // Rojo Material

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  INPUTS (campos de texto del login)                                    │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color inputFill   = Color(0x1A000000);       // 10% negro "tallado"
  static const Color inputBorder = Color(0x22000000);       // 13% negro

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  FAB / BOTÓN DE MARCAR ASISTENCIA                                      │
  // │  (el botón "+" flotante abajo a la derecha)                            │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color fabGradientStart = Color(0xFF00C4CC);  // Igual a primaryAccent
  static const Color fabGradientEnd   = Color(0xFF00A8AE);  // Teal oscuro

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  POPUP DE ÉXITO — Encabezado del check ✓                               │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color successCircleBg  = Color(0xFF4CAF50);  // Fondo del círculo ✓
  static const Color successIcon      = Color(0xFFFFFFFF);  // Ícono ✓

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  POPUP DE ERROR — Encabezado del X                                     │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color errorCircleBg = Color(0xFFE53935);     // Fondo del círculo X
  static const Color errorIcon     = Color(0xFFFFFFFF);     // Ícono X
}
