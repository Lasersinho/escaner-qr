import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A premium neo-morphic button that appears "raised" at rest
/// and subtly "pressed" on tap.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
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
              _pressed ? context.colors.primaryAccent.withOpacity(0.85) : context.colors.primaryAccent,
              _pressed ? context.colors.primaryAccent.withOpacity(0.85) : context.colors.primaryAccent.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        alignment: Alignment.center,
        child: widget.isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(context.colors.textOnAccent),
                ),
              )
            : Text(
                widget.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.colors.textOnAccent,
                ),
              ),
      ),
    );
  }
}
