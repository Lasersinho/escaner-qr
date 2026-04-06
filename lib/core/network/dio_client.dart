import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pre-configured [Dio] instance for OfficeFlow API calls.
class DioClient {
  DioClient({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://context.friomamut.pe/api/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: _tokenKey);

          if (token != null && !options.path.contains('/token')) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('--- REQUEST ---');
          print('METHOD: ${options.method}');
          print('URL: ${options.uri}');
          print('HEADERS: ${options.headers}');
          print('DATA: ${options.data}');

          handler.next(options);
        },
        onError: (error, handler) {
          print('--- ERROR ---');
          print('URL: ${error.requestOptions.uri}');
          print('HEADERS: ${error.requestOptions.headers}');
          print('STATUS: ${error.response?.statusCode}');
          print('BODY: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }

  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _secureStorage;
  late final Dio _dio;

  Dio get instance => _dio;
}
