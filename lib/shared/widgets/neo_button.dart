import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Visual style variants for [NeoButton].
enum NeoButtonVariant { primary, success, danger }

/// A premium neo-morphic button that appears "raised" at rest
/// and subtly "pressed" on tap, with optional icon and color variants.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.icon,
    this.variant = NeoButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  /// Optional leading icon displayed before the label.
  final IconData? icon;

  /// Color variant of the button.
  final NeoButtonVariant variant;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  Color _getColor(BuildContext context) {
    final colors = context.colors;
    return switch (widget.variant) {
      NeoButtonVariant.primary => colors.primaryAccent,
      NeoButtonVariant.success => colors.success,
      NeoButtonVariant.danger => colors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getColor(context);
    final colors = context.colors;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: widget.width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _pressed ? baseColor.withOpacity(0.85) : baseColor,
              _pressed
                  ? baseColor.withOpacity(0.85)
                  : baseColor.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: baseColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: widget.isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colors.textOnAccent),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: colors.textOnAccent, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.textOnAccent,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
