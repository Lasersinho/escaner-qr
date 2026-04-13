
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/attendance_repository.dart';
import '../data/office_repository.dart';
import '../data/proximity_service.dart';

// ── Service / Repository providers ──────────────────────────────────────────

/// Repositorio de oficinas. Hoy devuelve datos hardcodeados,
/// mañana se conecta a la BD.
final officeRepositoryProvider = Provider<OfficeRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dioClient = DioClient(secureStorage: storage);
  return OfficeRepository(dioClient: dioClient);
});

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
    this.errorMessage,
    this.formattedTime,
    this.officeName,
    this.type,
  });

  final AttendanceActionStatus status;
  final String? message;
  final String? errorMessage;
  final String? formattedTime;

  /// Nombre de la oficina donde se cambió (para mostrar en el popup).
  final String? officeName;
  
  /// El tipo de marcación (1 = Entrada, 2 = Salida)
  final int? type;

  AttendanceActionState copyWith({
    AttendanceActionStatus? status,
    String? message,
    String? errorMessage,
    String? formattedTime,
    String? officeName,
    int? type,
  }) =>
      AttendanceActionState(
        status: status ?? this.status,
        message: message ?? this.message,
        errorMessage: errorMessage,
        formattedTime: formattedTime ?? this.formattedTime,
        officeName: officeName ?? this.officeName,
        type: type ?? this.type,
      );
}

// ── Provider ────────────────────────────────────────────────────────────────

final attendanceActionProvider =
    StateNotifierProvider<AttendanceActionNotifier, AttendanceActionState>(
  (ref) => AttendanceActionNotifier(
    proximityService: ref.watch(proximityServiceProvider),
    repository: ref.watch(attendanceRepositoryProvider),
    secureStorage: ref.watch(secureStorageProvider),
  ),
);

class AttendanceActionNotifier extends StateNotifier<AttendanceActionState> {
  AttendanceActionNotifier({
    required ProximityService proximityService,
    required AttendanceRepository repository,
    required FlutterSecureStorage secureStorage,
  })  : _proximityService = proximityService,
        _repository = repository,
        _secureStorage = secureStorage,
        super(const AttendanceActionState());

  final ProximityService _proximityService;
  final AttendanceRepository _repository;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'attendance_session_token';

  /// Flujo completo al presionar el FAB "+":
  ///
  ///   1. Mostrar "Obteniendo ubicación..."
  ///   2. Validar GPS con ProximityService
  ///   3. Si detecta Mock GPS → error
  ///   4. Si está fuera de rango → remoto, si está dentro → oficina
  ///   5. Gestionar token de sesión en local storage
  ///   6. Registrar asistencia en el backend
  Future<void> processAttendance({int type = 1, String? existingToken}) async {
    print('Starting processAttendance, type: $type');
    // ── Estado: procesando ──
    state = state.copyWith(
      status: AttendanceActionStatus.securing,
      message: 'Obteniendo ubicación...',
    );

    try {
      // ── Paso 1: Validar proximidad con GPS real ──
      state = state.copyWith(message: 'Verificando ubicación GPS...');
      print('Validating proximity...');

      final result = await _proximityService.validateProximity();
      print('Proximity result: $result');

      
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
      

      // ── Paso 3: Verificar que esté dentro del radio o Remoto ──
      int headquarterId;
      String officeName;

      if (!result.isWithinRange) {
        headquarterId = 0; // ID designado para trabajo remoto
        officeName = 'Remoto';
        // Opcional: mostrar un warning o solicitar confirmación si se desea
        // pero por los requerimientos, simplemente se marca como remoto.
      } else {
        headquarterId = result.nearestOffice.id;
        officeName = result.nearestOffice.name;
      }

      // ── Paso 4: Generación/Validación de Token de Sesión ──
      state = state.copyWith(message: 'Preparando registro de asistencia...');
      String? token;

      if (type == 1) { // Entrada
        token = const Uuid().v4();
        print('[DEBUG] processAttendance: Generating new token for Entry: $token');
        await _secureStorage.write(key: _tokenKey, value: token);
      } else { // Salida
        // Use existing token if provided, otherwise fall back to stored token
        token = existingToken ?? await _secureStorage.read(key: _tokenKey);
        print('[DEBUG] processAttendance: Using token for Exit: $token (existingToken: $existingToken)');
        if (token == null) {
          print('[DEBUG] processAttendance: WARNING: No token found for Exit. Generating a contingency token.');
          // Si no hay token de entrada, genera uno por contingencia y previene null
          token = const Uuid().v4();
          print('[DEBUG] processAttendance: Contingency token: $token');
        }
      }

      // ── Paso 5: Ubicación válida → registrar asistencia ──
      state = state.copyWith(message: 'Registrando asistencia en $officeName...');
      print('[DEBUG] processAttendance: Calling repository.markAttendance(type: $type, headquarter: $headquarterId)');

      // Call the API to mark attendance
      final success = await _repository.markAttendance(
        type: type,
        token: token,
        headquarter: headquarterId,
        latitude: result.latitude,
        longitude: result.longitude,
        timestamp: DateTime.now(),
      );
      print('[DEBUG] processAttendance: Repository returned success: $success');

      // ── Paso 6: Limpieza post-salida ──
      if (type == 2) {
        print('[DEBUG] processAttendance: Deleting token from storage after successful Exit.');
        await _secureStorage.delete(key: _tokenKey);
      }

      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');

      // ── Paso 7: Éxito ──
      state = state.copyWith(
        status: AttendanceActionStatus.success,
        formattedTime: '$hh:$mm',
        officeName: officeName,
        type: type,
      );
      print('Process completed successfully');
    } on ProximityException catch (e) {
      print('ProximityException: $e');
      state = state.copyWith(
        status: AttendanceActionStatus.failure,
        errorMessage: e.message,
      );
    } on AttendanceException catch (e) {
      print('AttendanceException: $e');
      state = state.copyWith(
        status: AttendanceActionStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      print('Unexpected error: $e');
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
