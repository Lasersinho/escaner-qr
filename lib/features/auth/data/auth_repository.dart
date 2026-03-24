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
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';

  /// Simulates a login request. Always succeeds after a short delay.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    const fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock_token';
    final name = email.split('@').first;
    const id = 'usr_001';

    // Persist token and user info securely
    await _secureStorage.write(key: _tokenKey, value: fakeToken);
    await _secureStorage.write(key: _userNameKey, value: name);
    await _secureStorage.write(key: _userEmailKey, value: email);
    await _secureStorage.write(key: _userIdKey, value: id);

    return User(id: id, name: name, email: email);
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

  /// Restores the [User] from secure storage (null if not found).
  Future<User?> getStoredUser() async {
    final id = await _secureStorage.read(key: _userIdKey);
    final name = await _secureStorage.read(key: _userNameKey);
    final email = await _secureStorage.read(key: _userEmailKey);
    if (id == null || name == null || email == null) return null;
    return User(id: id, name: name, email: email);
  }

  /// Removes persisted credentials.
  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }
}
