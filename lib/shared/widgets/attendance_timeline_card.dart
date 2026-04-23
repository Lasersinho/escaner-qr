import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../features/attendance/domain/attendance_record.dart';

/// A timeline-style attendance card with a vertical connector line
/// and status dot, giving a clear temporal flow.
class AttendanceTimelineCard extends StatelessWidget {
  const AttendanceTimelineCard({
    super.key,
    required this.record,
    this.isFirst = false,
    this.isLast = false,
  });

  final AttendanceRecord record;

  /// True if this is the first item in the day group (hides top connector).
  final bool isFirst;

  /// True if this is the last item in the day group (hides bottom connector).
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEntry = record.type == AttendanceType.entry;
    final timeStr = DateFormat('hh:mm a').format(record.dateTime);
    final accentColor = isEntry ? colors.success : colors.secondaryAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Timeline column ──
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  // Top connector line
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : colors.timelineLine,
                    ),
                  ),
                  // Dot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  // Bottom connector line
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : colors.timelineLine,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Content card ──
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.glassShadow.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ── Icon ──
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEntry ? Icons.login_rounded : Icons.logout_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ── Text ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isEntry ? 'Entrada' : 'Salida',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            record.officeName ?? 'Ubicación desconocida',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Time badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        timeStr,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
