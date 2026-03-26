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
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
          reverseCurve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        );
        final scaleCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.fastLinearToSlowEaseIn,
          reverseCurve: Curves.fastOutSlowIn,
        );

        return FadeTransition(
          opacity: fadeCurve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(scaleCurve),
            child: child,
          ),
        );
      },
    );
  }

  // ── 2. Slide Up & Fade (Spring-like) ────────────────────────────────────
  /// Slides the view up from the bottom with a slight fade and a fluid spring-like slow settlement.
  /// Ideal for modal-like screens like Profile.
  static CustomTransitionPage<T> slideUp<T>({
    required Widget child,
    LocalKey? key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.fastLinearToSlowEaseIn,
          reverseCurve: Curves.fastOutSlowIn,
        );
        
        final fadeCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.15), // Start lower for more dramatic entry
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: fadeCurve,
            child: child,
          ),
        );
      },
    );
  }
}
