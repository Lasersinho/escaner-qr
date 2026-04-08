import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart';
import '../domain/user.dart';
import '../../attendance/data/device_identity_service.dart';

/// Repository handling authentication logic.
class AuthRepository {
  AuthRepository({
    required FlutterSecureStorage secureStorage,
    required DioClient dioClient,
  })  : _secureStorage = secureStorage,
        _dio = dioClient.instance;

  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';

  /// Performs login request to the API.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Logging in with email: $email');

      final deviceId = await DeviceIdentityService().getDeviceIdentifier();
      print('Device identifier for login: $deviceId');

      final response = await _dio.post(
        'https://context.friomamut.pe/token',
        data: {
          'username': email,
          'password': password,
          'device': deviceId,
        },
      );
      print('Login response: ${response.data}');

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final expiration = data['expiration'] as String;
      print('Token: $token');

      // Extract user info from token or assume from email
      final name = email.split('@').first;
      const id = 'usr_001'; // Or extract from token if available

      // Persist token and user info securely
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _userNameKey, value: name);
      await _secureStorage.write(key: _userEmailKey, value: email);
      await _secureStorage.write(key: _userIdKey, value: id);

      return User(id: id, name: name, email: email);
    } on DioException catch (e) {
      print('DioException in login: ${e.message}, response: ${e.response?.data}');
      throw Exception('Login failed: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Unexpected error in login: $e');
      throw Exception('Login failed: $e');
    }
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
