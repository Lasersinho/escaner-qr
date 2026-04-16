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
  static const String _userLastnameKey = 'user_lastname';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  static const String _userDocumentKey = 'user_document';

  FlutterSecureStorage get secureStorage => _secureStorage;

  // Getters for storage keys
  String get userNameKey => _userNameKey;
  String get userLastnameKey => _userLastnameKey;
  String get userEmailKey => _userEmailKey;
  String get userIdKey => _userIdKey;
  String get userDocumentKey => _userDocumentKey;

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

      await _secureStorage.write(key: _tokenKey, value: token);

      final infoResponse = await _dio.get('information');
      print('Information response: ${infoResponse.data}');
      final infoData = infoResponse.data as Map<String, dynamic>;

      final document = infoData['document'] as String;
      final name = infoData['name'] as String;
      final lastname = infoData['lastname'] as String;
      final id = document;

      await _secureStorage.write(key: _userNameKey, value: name);
      await _secureStorage.write(key: _userLastnameKey, value: lastname);
      await _secureStorage.write(key: _userEmailKey, value: email);
      await _secureStorage.write(key: _userIdKey, value: id);
      await _secureStorage.write(key: _userDocumentKey, value: document);

      return User(
        id: id,
        name: name,
        lastname: lastname,
        email: email,
        document: document,
      );
    } on DioException catch (e) {
      print('DioException in login: ${e.message}, response: ${e.response?.data}');

      // Handle specific HTTP status codes
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acceso denegado - dispositivo no autorizado');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Error interno del servidor');
      } else if (e.response?.statusCode == 400) {
        final dynamic data = e.response?.data;
        String message = 'Datos inválidos';
        
        if (data is Map) {
          message = data['message'] ?? (data['error'] ?? 'Datos inválidos');
        } else if (data is String) {
          message = data;
        }
        
        throw Exception(message);
      }

      // Handle network errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión');
      }

      // Generic Dio error
      throw Exception('Error de red: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Unexpected error in login: $e');
      throw Exception('Error inesperado en el login');
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
    final lastname = await _secureStorage.read(key: _userLastnameKey);
    final email = await _secureStorage.read(key: _userEmailKey);
    final document = await _secureStorage.read(key: _userDocumentKey);

    if (id == null || name == null || lastname == null || email == null || document == null) {
      return null;
    }

    return User(
      id: id,
      name: name,
      lastname: lastname,
      email: email,
      document: document,
    );
  }

  /// Removes persisted credentials.
  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }
}
