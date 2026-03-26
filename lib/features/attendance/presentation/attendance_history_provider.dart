import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/attendance_record.dart';

// ── Time Filter ─────────────────────────────────────────────────────────────

enum AttendanceTimeFilter { today, week, month, custom }

extension AttendanceTimeFilterLabel on AttendanceTimeFilter {
  String get label {
    switch (this) {
      case AttendanceTimeFilter.today:
        return 'Hoy';
      case AttendanceTimeFilter.week:
        return 'Semana';
      case AttendanceTimeFilter.month:
        return 'Mes';
      case AttendanceTimeFilter.custom:
        return 'Fecha';
    }
  }
}

// ── History State ────────────────────────────────────────────────────────────

class AttendanceHistoryState {
  const AttendanceHistoryState({
    this.filter = AttendanceTimeFilter.week,
    this.customDate,
    this.allRecords = const [],
  });

  final AttendanceTimeFilter filter;
  final DateTime? customDate;
  final List<AttendanceRecord> allRecords;

  /// Returns records filtered by the current [filter], sorted descending.
  List<AttendanceRecord> get filteredRecords {
    if (filter == AttendanceTimeFilter.custom && customDate != null) {
      final targetDate = DateTime(customDate!.year, customDate!.month, customDate!.day);
      return allRecords.where((r) {
        final rDate = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
        return rDate.isAtSameMomentAs(targetDate);
      }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }

    final now = DateTime.now();
    final cutoff = switch (filter) {
      AttendanceTimeFilter.today => DateTime(now.year, now.month, now.day),
      AttendanceTimeFilter.week =>
        now.subtract(const Duration(days: 6)),
      AttendanceTimeFilter.month =>
        now.subtract(const Duration(days: 29)),
      AttendanceTimeFilter.custom =>
        now.subtract(const Duration(days: 6)), // Fallback
    };
    return allRecords
        .where((r) => r.dateTime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Groups [filteredRecords] by calendar day (yyyy-MM-dd).
  Map<DateTime, List<AttendanceRecord>> get groupedByDay {
    final grouped = <DateTime, List<AttendanceRecord>>{};
    for (final record in filteredRecords) {
      final day = DateTime(
        record.dateTime.year,
        record.dateTime.month,
        record.dateTime.day,
      );
      grouped.putIfAbsent(day, () => []).add(record);
    }
    return grouped;
  }

  AttendanceHistoryState copyWith({
    AttendanceTimeFilter? filter,
    DateTime? customDate,
    List<AttendanceRecord>? allRecords,
  }) =>
      AttendanceHistoryState(
        filter: filter ?? this.filter,
        customDate: customDate ?? this.customDate,
        allRecords: allRecords ?? this.allRecords,
      );
}

// ── Mock data ────────────────────────────────────────────────────────────────

List<AttendanceRecord> _generateMockRecords() {
  final now = DateTime.now();
  final records = <AttendanceRecord>[];
  int idCounter = 1;

  // Generate entry+exit pairs for the past 10 days
  for (int d = 0; d < 10; d++) {
    final day = now.subtract(Duration(days: d));
    // Skip weekends for realism
    if (day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday) {
      continue;
    }

    records.add(AttendanceRecord(
      id: 'rec_${idCounter++}',
      type: AttendanceType.entry,
      dateTime: DateTime(
          day.year, day.month, day.day, 8, 5 + (idCounter % 30)),
      employeeId: 'usr_001',
    ));

    records.add(AttendanceRecord(
      id: 'rec_${idCounter++}',
      type: AttendanceType.exit,
      dateTime: DateTime(
          day.year, day.month, day.day, 17, 30 + (idCounter % 20)),
      employeeId: 'usr_001',
    ));
  }

  return records;
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class AttendanceHistoryNotifier
    extends StateNotifier<AttendanceHistoryState> {
  AttendanceHistoryNotifier()
      : super(AttendanceHistoryState(allRecords: _generateMockRecords()));

  void setFilter(AttendanceTimeFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setCustomDate(DateTime date) {
    state = state.copyWith(filter: AttendanceTimeFilter.custom, customDate: date);
  }

  /// Call after a successful QR scan to add a new entry/exit record.
  void addRecord(AttendanceRecord record) {
    state = state.copyWith(
      allRecords: [record, ...state.allRecords],
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final attendanceHistoryProvider = StateNotifierProvider<
    AttendanceHistoryNotifier, AttendanceHistoryState>(
  (ref) => AttendanceHistoryNotifier(),
);
