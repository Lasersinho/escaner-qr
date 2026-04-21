import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
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
    this.filter = AttendanceTimeFilter.today,
    this.customDateRange,
    this.allRecords = const [],
  });

  final AttendanceTimeFilter filter;
  final DateTimeRange? customDateRange;
  final List<AttendanceRecord> allRecords;

  /// Returns the most recent record from the full history,
  /// regardless of the active UI filter.
  AttendanceRecord? get latestRecord {
    if (allRecords.isEmpty) return null;

    AttendanceRecord latest = allRecords.first;
    for (final record in allRecords.skip(1)) {
      if (record.dateTime.isAfter(latest.dateTime)) {
        latest = record;
      }
    }
    return latest;
  }

  /// Returns records filtered by the current [filter], sorted descending.
  List<AttendanceRecord> get filteredRecords {
    if (filter == AttendanceTimeFilter.custom && customDateRange != null) {
      final start = DateTime(customDateRange!.start.year, customDateRange!.start.month, customDateRange!.start.day);
      final end = DateTime(customDateRange!.end.year, customDateRange!.end.month, customDateRange!.end.day, 23, 59, 59);

      return allRecords.where((r) {
        return r.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) && r.dateTime.isBefore(end.add(const Duration(seconds: 1)));
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
    DateTimeRange? customDateRange,
    List<AttendanceRecord>? allRecords,
  }) =>
      AttendanceHistoryState(
        filter: filter ?? this.filter,
        customDateRange: customDateRange ?? this.customDateRange,
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
      officeName: idCounter % 5 == 0 ? 'Remoto' : 'Miraflores',
    ));

    records.add(AttendanceRecord(
      id: 'rec_${idCounter++}',
      type: AttendanceType.exit,
      dateTime: DateTime(
          day.year, day.month, day.day, 17, 30 + (idCounter % 20)),
      employeeId: 'usr_001',
      officeName: idCounter % 5 == 0 ? 'Remoto' : 'Miraflores',
    ));
  }

  return records;
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class AttendanceHistoryNotifier
    extends StateNotifier<AttendanceHistoryState> {
  AttendanceHistoryNotifier(this._dio) : super(const AttendanceHistoryState()) {
    fetchHistory();
  }

  final Dio _dio;

  Future<void> fetchHistory() async {
    try {
      final response = await _dio.get('/turnouts');
      final List data = response.data as List;
      final records = data.map((json) => AttendanceRecord.fromJson(json)).toList();
      state = state.copyWith(allRecords: records);
    } catch (e) {
      // Handle error, maybe keep mock or show error
      state = state.copyWith(allRecords: _generateMockRecords());
    }
  }

  void setFilter(AttendanceTimeFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setCustomDateRange(DateTimeRange range) {
    state = state.copyWith(filter: AttendanceTimeFilter.custom, customDateRange: range);
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
  (ref) => AttendanceHistoryNotifier(
    DioClient(secureStorage: ref.watch(secureStorageProvider)).instance,
  ),
);
