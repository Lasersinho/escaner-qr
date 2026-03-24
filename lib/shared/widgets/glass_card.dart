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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTokens.blurSigma,
            sigmaY: AppTokens.blurSigma,
          ),
          child: Container(
            padding: padding ?? AppTokens.paddingCard,
            decoration: BoxDecoration(
              color: AppColors.glassPanel,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.glassBorder, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
