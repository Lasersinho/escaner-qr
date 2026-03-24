import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/attendance_repository.dart';
import '../data/location_service.dart';
import '../domain/scan_result.dart';

// ── Service / Repository providers ──────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dioClient = DioClient(secureStorage: storage);
  return AttendanceRepository(dioClient: dioClient);
});

// ── Attendance Action State ─────────────────────────────────────────────────

enum AttendanceActionStatus { idle, processing, success, failure }

class AttendanceActionState {
  const AttendanceActionState({
    this.status = AttendanceActionStatus.idle,
    this.scanResult,
    this.errorMessage,
    this.formattedTime,
  });

  final AttendanceActionStatus status;
  final ScanResult? scanResult;
  final String? errorMessage;
  final String? formattedTime;

  AttendanceActionState copyWith({
    AttendanceActionStatus? status,
    ScanResult? scanResult,
    String? errorMessage,
    String? formattedTime,
  }) =>
      AttendanceActionState(
        status: status ?? this.status,
        scanResult: scanResult ?? this.scanResult,
        errorMessage: errorMessage,
        formattedTime: formattedTime ?? this.formattedTime,
      );
}

// ── Provider ────────────────────────────────────────────────────────────────

final attendanceActionProvider =
    StateNotifierProvider<AttendanceActionNotifier, AttendanceActionState>(
  (ref) => AttendanceActionNotifier(
    locationService: ref.watch(locationServiceProvider),
    repository: ref.watch(attendanceRepositoryProvider),
  ),
);

class AttendanceActionNotifier extends StateNotifier<AttendanceActionState> {
  AttendanceActionNotifier({
    required LocationService locationService,
    required AttendanceRepository repository,
  })  : _locationService = locationService,
        _repository = repository,
        super(const AttendanceActionState());

  final LocationService _locationService;
  final AttendanceRepository _repository;

  /// Full departure flow: location → build model → call API.
  Future<void> processScan(String qrData) async {
    state = state.copyWith(status: AttendanceActionStatus.processing);

    try {
      // 1. Get location
      final position = await _locationService.getCurrentPosition();

      // 2. Timestamp
      final now = DateTime.now();

      // 3. Build ScanResult
      final result = ScanResult(
        timestamp: now,
        latitude: position.latitude,
        longitude: position.longitude,
        qrData: qrData,
        employeeId: 'usr_001', // In production, pull from auth state
        deviceInfo: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );

      // 4. Call API
      await _repository.markDeparture(result);

      // 5. Format time for UI
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');

      state = state.copyWith(
        status: AttendanceActionStatus.success,
        scanResult: result,
        formattedTime: '$hh:$mm',
      );
    } catch (e) {
      state = state.copyWith(
        status: AttendanceActionStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset to idle so the scanner can be reused.
  void reset() {
    state = const AttendanceActionState();
  }
}
