import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Provides premium custom page transitions for the app's routing.
abstract final class AppPageTransitions {
  // ── 1. Fade & Scale ───────────────────────────────────────────────────────
  /// A subtle scale-up (0.95 -> 1.0) paired with a smooth fade.
  /// Ideal for top-level navigation like Login -> Home or Scanner.
  static CustomTransitionPage<T> fadeScale<T>({
    required Widget child,
    LocalKey? key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        final scaleCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: fadeCurve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(scaleCurve),
            child: child,
          ),
        );
      },
    );
  }

  // ── 2. Slide Up & Fade ──────────────────────────────────────────────────
  /// Slides the view up from the bottom with a slight fade.
  /// Ideal for modal-like screens like Profile.
  static CustomTransitionPage<T> slideUp<T>({
    required Widget child,
    LocalKey? key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.08), // Start slightly below
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: child,
          ),
        );
      },
    );
  }
}
