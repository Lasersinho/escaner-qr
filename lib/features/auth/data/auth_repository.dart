import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/user.dart';

/// Repository handling authentication logic.
///
/// This is a **mock** implementation: any email/password combination
/// will succeed, returning a fake JWT token and user object.
class AuthRepository {
  AuthRepository({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'auth_token';

  /// Simulates a login request. Always succeeds after a short delay.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    const fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock_token';

    // Persist token securely
    await _secureStorage.write(key: _tokenKey, value: fakeToken);

    return User(
      id: 'usr_001',
      name: email.split('@').first,
      email: email,
    );
  }

  /// Checks whether a persisted token exists.
  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Reads the stored auth token.
  Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  /// Removes persisted credentials.
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
