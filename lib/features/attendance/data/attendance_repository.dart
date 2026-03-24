import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/scan_result.dart';

/// Repository that sends attendance departure records to the backend.
class AttendanceRepository {
  AttendanceRepository({required DioClient dioClient})
      : _dio = dioClient.instance;

  final Dio _dio;

  /// POST the [ScanResult] to the departure endpoint.
  ///
  /// Returns `true` on success, throws on failure.
  Future<bool> markDeparture(ScanResult result) async {
    try {
      final response = await _dio.post(
        '/departure',
        data: result.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw AttendanceException(
        e.response?.data?['message']?.toString() ??
            'No se pudo registrar la salida. Intente de nuevo.',
      );
    }
  }
}

/// Exception thrown by [AttendanceRepository].
class AttendanceException implements Exception {
  const AttendanceException(this.message);
  final String message;

  @override
  String toString() => 'AttendanceException: $message';
}
