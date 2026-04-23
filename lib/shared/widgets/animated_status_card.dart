import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A prominent "hero" card that shows the user's current attendance status.
///
/// Displays a greeting, current state (active/inactive), elapsed time,
/// and the primary action button with clear labeling.
class AnimatedStatusCard extends StatefulWidget {
  const AnimatedStatusCard({
    super.key,
    required this.userName,
    required this.isActive,
    this.activeSince,
    this.officeName,
    required this.nextActionLabel,
    required this.nextActionIcon,
    required this.onActionPressed,
    this.isProcessing = false,
    this.serverNow,
  });

  /// First name of the user for the greeting.
  final String userName;

  /// Whether the user currently has an active entry (clocked in).
  final bool isActive;

  /// The time the current session started (if active).
  /// Must come from the server (Peru time), NOT DateTime.now().
  final DateTime? activeSince;

  /// Office name where the user clocked in.
  final String? officeName;

  /// Text for the main action button (e.g. "Marcar Entrada" / "Marcar Salida").
  final String nextActionLabel;

  /// Icon for the main action button.
  final IconData nextActionIcon;

  /// Callback when the action button is pressed.
  final VoidCallback onActionPressed;

  /// Whether an attendance action is currently being processed.
  final bool isProcessing;

  /// Current server time (Peru). Used instead of DateTime.now() for
  /// computing elapsed time and the greeting, so device clock changes
  /// don't corrupt the display. Falls back to activeSince-based delta
  /// when null.
  final DateTime? serverNow;

  @override
  State<AnimatedStatusCard> createState() => _AnimatedStatusCardState();
}

class _AnimatedStatusCardState extends State<AnimatedStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _startElapsedTimer();
  }

  @override
  void didUpdateWidget(covariant AnimatedStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.activeSince != widget.activeSince) {
      _startElapsedTimer();
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    if (widget.isActive && widget.activeSince != null) {
      _updateElapsed();
      _elapsedTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _updateElapsed(),
      );
    } else {
      _elapsed = Duration.zero;
    }
  }

  void _updateElapsed() {
    if (!mounted) return;
    setState(() {
      // Use serverNow when available so elapsed time is correct even if the
      // device clock has been changed manually. Fall back to DateTime.now()
      // only as a last resort (e.g. offline before any successful mark).
      final referenceNow = widget.serverNow ?? DateTime.now();
      final diff = referenceNow.difference(widget.activeSince!);
      // Guard against negative values caused by clock skew.
      _elapsed = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    // Use server time (Peru) for the greeting so it doesn't flip when
    // the user manually changes their device clock.
    final hour = (widget.serverNow ?? widget.activeSince ?? DateTime.now()).hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes} min';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isActive = widget.isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [colors.statusActiveStart, colors.statusActiveEnd]
              : [colors.statusInactiveStart, colors.statusInactiveEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive
                    ? colors.statusActiveStart
                    : colors.statusInactiveStart)
                .withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting row ──
          Row(
            children: [
              Icon(
                isActive ? Icons.wb_sunny_rounded : Icons.waving_hand_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_getGreeting()}, ${widget.userName.split(' ').first}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Status text ──
          Text(
            isActive ? 'Estás activo' : 'Sin marcar hoy',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),

          if (isActive && widget.activeSince != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: Colors.white.withOpacity(0.85), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Desde las ${_formatTime(widget.activeSince!)} · ${_formatElapsed(_elapsed)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (widget.officeName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: Colors.white.withOpacity(0.85), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.officeName!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Presiona el botón para registrar tu asistencia',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Action Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: widget.isProcessing ? null : widget.onActionPressed,
              icon: widget.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(widget.nextActionIcon, size: 22),
              label: Text(
                widget.isProcessing ? 'Procesando...' : widget.nextActionLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
