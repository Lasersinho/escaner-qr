
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/attendance_repository.dart';
import '../data/office_repository.dart';
import '../data/proximity_service.dart';
import '../domain/scan_result.dart';

// ── Service / Repository providers ──────────────────────────────────────────

/// Repositorio de oficinas. Hoy devuelve datos hardcodeados,
/// mañana se conecta a la BD.
final officeRepositoryProvider = Provider<OfficeRepository>(
  (ref) => OfficeRepository(),
);

/// Servicio de proximidad. Recibe el repositorio de oficinas
/// y valida si el usuario está cerca de alguna.
final proximityServiceProvider = Provider<ProximityService>(
  (ref) => ProximityService(
    officeRepository: ref.watch(officeRepositoryProvider),
  ),
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
    this.officeName,
  });

  final AttendanceActionStatus status;
  final String? message;
  final ScanResult? scanResult;
  final String? errorMessage;
  final String? formattedTime;

  /// Nombre de la oficina donde se marcó (para mostrar en el popup).
  final String? officeName;

  AttendanceActionState copyWith({
    AttendanceActionStatus? status,
    String? message,
    ScanResult? scanResult,
    String? errorMessage,
    String? formattedTime,
    String? officeName,
  }) =>
      AttendanceActionState(
        status: status ?? this.status,
        message: message ?? this.message,
        scanResult: scanResult ?? this.scanResult,
        errorMessage: errorMessage,
        formattedTime: formattedTime ?? this.formattedTime,
        officeName: officeName ?? this.officeName,
      );
}

// ── Provider ────────────────────────────────────────────────────────────────

final attendanceActionProvider =
    StateNotifierProvider<AttendanceActionNotifier, AttendanceActionState>(
  (ref) => AttendanceActionNotifier(
    proximityService: ref.watch(proximityServiceProvider),
    repository: ref.watch(attendanceRepositoryProvider),
  ),
);

class AttendanceActionNotifier extends StateNotifier<AttendanceActionState> {
  AttendanceActionNotifier({
    required ProximityService proximityService,
    required AttendanceRepository repository,
  })  : _proximityService = proximityService,
        _repository = repository,
        super(const AttendanceActionState());

  final ProximityService _proximityService;
  final AttendanceRepository _repository;

  /// Flujo completo al presionar el FAB "+":
  ///
  ///   1. Mostrar "Obteniendo ubicación..."
  ///   2. Validar GPS con ProximityService
  ///   3. Si detecta Mock GPS → error
  ///   4. Si está fuera de rango → error con distancia
  ///   5. Si está dentro de rango → éxito con hora y nombre de oficina
  Future<void> processScan(String qrData) async {
    // ── Estado: procesando ──
    state = state.copyWith(
      status: AttendanceActionStatus.securing,
      message: 'Obteniendo ubicación...',
    );

    try {
      // ── Paso 1: Validar proximidad con GPS real ──
      state = state.copyWith(message: 'Verificando ubicación GPS...');

      final result = await _proximityService.validateProximity();

      // ── Paso 2: Detectar ubicación falsa (Fake GPS) ──
      if (result.isMocked) {
        state = state.copyWith(
          status: AttendanceActionStatus.failure,
          errorMessage:
              '⚠️ Se detectó una aplicación de ubicación falsa (Mock GPS). '
              'Desinstálala para poder marcar asistencia.',
        );
        return;
      }

      // ── Paso 3: Verificar que esté dentro del radio ──
      if (!result.isWithinRange) {
        state = state.copyWith(
          status: AttendanceActionStatus.failure,
          errorMessage:
              'Estás a ${result.formattedDistance} de "${result.nearestOffice.name}". '
              'Debes estar a menos de ${result.nearestOffice.allowedRadiusMeters.toStringAsFixed(0)} m '
              'para marcar asistencia.',
        );
        return;
      }

      // ── Paso 4: Ubicación válida → registrar asistencia ──
      state = state.copyWith(message: 'Registrando asistencia...');

      // TODO: Aquí se conectará con el backend real.
      // await _repository.markAttendance(...);
      // Por ahora simulamos un pequeño delay de red:
      await Future.delayed(const Duration(milliseconds: 500));

      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');

      // ── Paso 5: Éxito ──
      state = state.copyWith(
        status: AttendanceActionStatus.success,
        formattedTime: '$hh:$mm',
        officeName: result.nearestOffice.name,
      );
    } on ProximityException catch (e) {
      state = state.copyWith(
        status: AttendanceActionStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AttendanceActionStatus.failure,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  void reset() {
    state = const AttendanceActionState();
  }
}
