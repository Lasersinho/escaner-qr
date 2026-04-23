import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A visually rich bottom sheet that replaces the opaque overlay,
/// showing step-by-step progress during attendance processing.
class ProcessingBottomSheet extends StatelessWidget {
  const ProcessingBottomSheet({
    super.key,
    required this.message,
    this.steps = const [],
  });

  final String message;

  /// Optional list of processing steps with their completion status.
  final List<ProcessingStep> steps;

  static void show(BuildContext context, {required String message}) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ProcessingBottomSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
      decoration: BoxDecoration(
        color: colors.glassPanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colors.glassShadow.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textDisabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 28),

          // ── Animated indicator ──
          _PulsingIndicator(color: colors.primaryAccent),

          const SizedBox(height: 24),

          // ── Main message ──
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Por favor no cierres la aplicación',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// A step in the processing pipeline.
class ProcessingStep {
  const ProcessingStep({
    required this.label,
    this.isCompleted = false,
    this.isActive = false,
  });

  final String label;
  final bool isCompleted;
  final bool isActive;
}

/// A pulsating ring indicator for the processing state.
class _PulsingIndicator extends StatefulWidget {
  const _PulsingIndicator({required this.color});
  final Color color;

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Pulsing ring ──
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _opacityAnim.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // ── Center dot ──
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.15),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(widget.color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
