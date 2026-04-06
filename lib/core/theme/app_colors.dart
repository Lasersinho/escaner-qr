import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🎨  PALETA DE COLORES — Pulse App (Edición Premium "Deep Indigo")
/// ═══════════════════════════════════════════════════════════════════════════
///
/// He seleccionado una paleta basada en Indigo y Slate Blue. 
/// Es una combinación que transmite confianza, profesionalismo y es
/// muy cómoda a la vista (menos "vibrante" que el teal puro).
/// ═══════════════════════════════════════════════════════════════════════════
abstract final class AppColors {

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  FONDO DE LA APP                                                       │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color backgroundStart = Color(0xFFF8FAFC);  // Slate muy claro
  static const Color backgroundEnd   = Color(0xFFFFFFFF);   // Blanco puro

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  COLORES PRINCIPALES (Indigo Moderno)                                  │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color primaryAccent   = Color(0xFF4F46E5);   // Indigo 600 (Elegante)
  static const Color secondaryAccent = Color(0xFF818CF8);   // Indigo claro

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  PANELES Y TARJETAS (100% Flat)                                        │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color glassPanel  = Color(0xFFFFFFFF);       // 100% blanco (totalmente opaco)
  static const Color glassBorder = Color(0x00FFFFFF);       // Sin borde transparente
  static const Color glassShadow = Color(0x00000000);       // Sin sombra

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  TEXTO                                                                 │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color textPrimary   = Color(0xFF1E293B);     // Slate oscuro (mejor contraste)
  static const Color textSecondary = Color(0xFF64748B);     // Slate grisáceo
  static const Color textOnAccent  = Color(0xFFFFFFFF);     // Blanco

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  ESTADO — Éxito / Error                                                │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color success = Color(0xFF10B981);           // Esmeralda (más moderno que el verde puro)
  static const Color error   = Color(0xFFF43F5E);           // Rose/Red moderno

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  INPUTS                                                                │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color inputFill   = Color(0x0F000000);       // Muy sutil
  static const Color inputBorder = Color(0x1A000000);       

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  FAB / BOTÓN DE MARCAR ASISTENCIA                                      │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color fabGradientStart = Color(0xFF4F46E5);  
  static const Color fabGradientEnd   = Color(0xFF4338CA);  // Indigo profundo

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  POPUP DE ÉXITO                                                        │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color successCircleBg  = Color(0xFF10B981);  
  static const Color successIcon      = Color(0xFFFFFFFF);  

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │  POPUP DE ERROR                                                        │
  // └─────────────────────────────────────────────────────────────────────────┘
  static const Color errorCircleBg = Color(0xFFF43F5E);     
  static const Color errorIcon     = Color(0xFFFFFFFF);     
}
