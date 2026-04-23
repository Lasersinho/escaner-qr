import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper that adds a subtle scale-down bouncing animation and haptic feedback
/// when the user presses it.
class BouncingWidget extends StatefulWidget {
  const BouncingWidget({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleFactor = 0.94,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onPressed;
  
  /// How much to scale down (e.g. 0.95 means 95% of original size)
  final double scaleFactor;
  
  /// Duration of the scale down animation
  final Duration duration;

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      HapticFeedback.mediumImpact();
      _controller.reverse();
      widget.onPressed?.call();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: IgnorePointer(
          ignoring: true, // Let the GestureDetector handle taps to trigger animation
          child: widget.child,
        ),
      ),
    );
  }
}
