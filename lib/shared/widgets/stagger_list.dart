import 'package:flutter/material.dart';

/// Wraps a child widget with a staggered fade + slide-up entrance animation.
///
/// Use inside a list to give each item a progressive delay,
/// creating a smooth cascade effect.
class StaggerItem extends StatefulWidget {
  const StaggerItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 250),
  });

  /// Position in the list; controls the stagger delay.
  final int index;
  final Widget child;

  /// Delay per item (multiplied by [index]).
  final Duration delay;

  /// Duration of the fade/slide animation.
  final Duration duration;

  @override
  State<StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<StaggerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Cap the stagger effect to the first 6 items.
    // If we multiply the delay by the index indefinitely, items far down the list
    // (e.g. index 30) will take several seconds to appear when scrolled into view.
    final int effectiveIndex = widget.index < 6 ? widget.index : 0;
    final Duration actualDelay = Duration(milliseconds: 30 * effectiveIndex);

    Future.delayed(actualDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}
