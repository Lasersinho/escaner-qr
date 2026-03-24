import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/attendance_repository.dart';
import '../data/camera_capture_service.dart';
import '../data/location_service.dart';
import '../domain/scan_result.dart';

// ── Service / Repository providers ──────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final cameraCaptureServiceProvider = Provider<CameraCaptureService>(
  (ref) => CameraCaptureService(),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dioClient = DioClient(secureStorage: storage);
  return AttendanceRepository(dioClient: dioClient);
});

// ── Attendance Action State ─────────────────────────────────────────────────

enum AttendanceActionStatus { idle, securing, success, failure }

class AttendanceActionState {
  const AttendanceActionState({
    this.status = AttendanceActionStatus.idle,
    this.message,
    this.scanResult,
    this.errorMessage,
    this.formattedTime,
  });

  final AttendanceActionStatus status;
  final String? message;
  final ScanResult? scanResult;
  final String? errorMessage;
  final String? formattedTime;

  AttendanceActionState copyWith({
    AttendanceActionStatus? status,
    String? message,
    ScanResult? scanResult,
    String? errorMessage,
    String? formattedTime,
  }) =>
      AttendanceActionState(
        status: status ?? this.status,
        message: message ?? this.message,
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
    cameraCaptureService: ref.watch(cameraCaptureServiceProvider),
    repository: ref.watch(attendanceRepositoryProvider),
  ),
);

class AttendanceActionNotifier extends StateNotifier<AttendanceActionState> {
  AttendanceActionNotifier({
    required LocationService locationService,
    required CameraCaptureService cameraCaptureService,
    required AttendanceRepository repository,
  })  : _locationService = locationService,
        _cameraCaptureService = cameraCaptureService,
        _repository = repository,
        super(const AttendanceActionState());

  final LocationService _locationService;
  final CameraCaptureService _cameraCaptureService;
  final AttendanceRepository _repository;

  /// Process scan: Securing (Dual Photos) -> Location -> API.
  Future<void> processScan(String qrData) async {
    // 1. Enter securing state with initial message
    state = state.copyWith(
      status: AttendanceActionStatus.securing,
      message: 'Verificando entorno...', // Text shown while back camera is preparing/shooting
    );

    try {
      // 2. Capture dual photos
      final images = await _cameraCaptureService.captureDualPhoto();

      // Change message for front camera
      state = state.copyWith(message: 'Verificando identidad...');

      // 3. Location
      final position = await _locationService.getCurrentPosition();

      // Ensure message reflects sending state so UI doesn't hang
      state = state.copyWith(message: 'Enviando...');

      // 4. Timestamp & Build Model
      final now = DateTime.now();
      final result = ScanResult(
        timestamp: now,
        latitude: position.latitude,
        longitude: position.longitude,
        qrData: qrData,
        employeeId: 'usr_001',
        deviceInfo: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        backPhotoPath: images.backPhotoPath,
        frontPhotoPath: images.frontPhotoPath,
      );

      // 5. Call API
      await _repository.markDeparture(result);

      // 6. Format time and succeed
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

  void reset() {
    state = const AttendanceActionState();
  }
}
