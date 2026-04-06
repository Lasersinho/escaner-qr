import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

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
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// ── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;

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
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await _repo.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clear session.
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}
