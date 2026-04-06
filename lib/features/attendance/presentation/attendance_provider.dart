
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

  /// Process scan: Securing (Dual Photos) -> Location -> API.
  Future<void> processScan(String qrData) async {
    // 1. Enter securing state with initial message
    state = state.copyWith(
      status: AttendanceActionStatus.securing,
      message: 'Verificando entorno...', // Text shown while back camera is preparing/shooting
    );

    try {
      // --- MOCK FOR UI TESTING ---
      // Simulate typical delay
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(message: 'Verificando identidad...');
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(message: 'Enviando...');
      await Future.delayed(const Duration(seconds: 1));
      
      final now = DateTime.now();
      
      // 6. Format time and succeed
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');

      state = state.copyWith(
        status: AttendanceActionStatus.success,
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
