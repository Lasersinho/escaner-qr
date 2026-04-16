import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A translucent, backdrop-blurred card that implements the Glass-Neo style.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTokens.radiusPanel;

    return Container(
      width: width,
      padding: padding ?? AppTokens.paddingCard,
      decoration: BoxDecoration(
        color: context.colors.glassPanel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: context.colors.glassBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.glassShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
