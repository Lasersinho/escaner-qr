import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pre-configured [Dio] instance for OfficeFlow API calls.
class DioClient {
  DioClient({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.mock.com/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Centralized error handling – extend as needed.
          return handler.next(error);
        },
      ),
    );
  }

  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _secureStorage;
  late final Dio _dio;

  Dio get instance => _dio;
}
