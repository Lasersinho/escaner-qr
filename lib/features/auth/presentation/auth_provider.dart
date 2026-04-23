import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';
import '../../attendance/presentation/attendance_history_provider.dart';
import '../../attendance/presentation/attendance_provider.dart';

// ── Auth State ──────────────────────────────────────────────────────────────

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
      );
}

// ── Providers ───────────────────────────────────────────────────────────────

/// Provides a singleton [FlutterSecureStorage] instance.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Provides [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    secureStorage: ref.watch(secureStorageProvider),
    dioClient: DioClient(secureStorage: ref.watch(secureStorageProvider)),
  ),
);

/// Main auth state notifier used throughout the app.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

// ── Error Handling ────────────────────────────────────────────────────────────

/// Converts technical error messages to user-friendly messages.
String _getUserFriendlyErrorMessage(Object error) {
  final errorString = error.toString().toLowerCase();

  // Network errors
  if (errorString.contains('tiempo de conexión agotado') ||
      errorString.contains('connection timeout')) {
    return 'La conexión está tardando demasiado. Verifica tu conexión a internet.';
  }
  if (errorString.contains('error de conexión') ||
      errorString.contains('connection error')) {
    return 'No se puede conectar al servidor. Verifica tu conexión a internet.';
  }
  if (errorString.contains('error de red') || errorString.contains('network')) {
    return 'Problema de conexión. Inténtalo nuevamente.';
  }

  // Authentication errors
  if (errorString.contains('credenciales inválidas') ||
      errorString.contains('401')) {
    return 'DNI o contraseña incorrectos. Verifícalos e intenta nuevamente.';
  }
  if (errorString.contains('acceso denegado') ||
      errorString.contains('dispositivo no autorizado') ||
      errorString.contains('403')) {
    return 'Este dispositivo no está autorizado. Contacta al administrador.';
  }

  // Server errors
  if (errorString.contains('error interno del servidor') ||
      errorString.contains('500')) {
    return 'Problema temporal del servidor. Inténtalo en unos minutos.';
  }
  if (errorString.contains('error de validación') ||
      errorString.contains('400')) {
    return 'Los datos enviados no son válidos. Verifica la información.';
  }

  // Device binding errors
  if (errorString.contains('ya se encuentra en otro dispositivo')) {
    return 'Tu cuenta ya está vinculada a otro dispositivo. Si reinstalaste la app o cambiaste de equipo, contacta al administrador para desvincular la sesión anterior.';
  }
  if (errorString.contains('dispositivo') || errorString.contains('device')) {
    return 'Error de identificación del dispositivo. Verifica los permisos e intenta nuevamente.';
  }

  // Generic errors
  if (errorString.contains('inesperado') ||
      errorString.contains('unexpected')) {
    return 'Ocurrió un error inesperado. Inténtalo nuevamente.';
  }

  // Default fallback
  return 'No se pudo iniciar sesión. Verifica tus datos e intenta nuevamente.';
}

// ── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._ref) : super(const AuthState());

  final AuthRepository _repo;
  final Ref _ref;

  /// Check whether a token already exists (restoring session).
  Future<void> checkSession() async {
    final hasToken = await _repo.hasToken();
    if (hasToken) {
      final user = await _repo.getStoredUser();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    }
  }

  /// Attempt login with the given credentials.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state =
        state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getUserFriendlyErrorMessage(e),
      );
    }
  }

  /// Clear session.
  Future<void> logout() async {
    await _repo.logout();

    // Reset all states to prevent data leakage between sessions
    state = const AuthState();

    // Clear attendance-related data
    _ref.invalidate(attendanceHistoryProvider);
    _ref.invalidate(attendanceActionProvider);
  }

  /// Refresh user information from the API.
  Future<void> refreshUserInfo() async {
    try {
      final token = await _repo.getToken();
      if (token == null) return;

      // Create a new Dio instance for the information call
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://context.friomamut.pe/api/',
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final infoResponse = await dio.get('information');
      final infoData = infoResponse.data as Map<String, dynamic>;

      final document = infoData['document'] as String;
      final name = infoData['name'] as String;
      final lastname = infoData['lastname'] as String;
      final email = infoData['email'] as String;
      final id = document;

      // Update stored user info
      await _repo.secureStorage.write(key: _repo.userNameKey, value: name);
      await _repo.secureStorage
          .write(key: _repo.userLastnameKey, value: lastname);
      await _repo.secureStorage.write(key: _repo.userEmailKey, value: email);
      await _repo.secureStorage.write(key: _repo.userIdKey, value: id);
      await _repo.secureStorage
          .write(key: _repo.userDocumentKey, value: document);

      final updatedUser = User(
        id: id,
        name: name,
        lastname: lastname,
        email: email,
        document: document,
      );

      state = state.copyWith(user: updatedUser);
    } catch (e) {
      // If refresh fails, keep the current user data
      print('Failed to refresh user info: $e');
    }
  }
}
