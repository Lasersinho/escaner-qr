import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/network/dio_client.dart';

/// Repository that sends attendance departure records to the backend.
class AttendanceRepository {
  AttendanceRepository({required DioClient dioClient})
      : _dio = dioClient.instance;

  final Dio _dio;

  /// POST to the turnouts endpoint for attendance marking.
  ///
  /// Returns `true` on success, throws on failure.
  Future<bool> markAttendance({
    required int type,
    required String token,
    required int headquarter,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    try {
      final formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

      final data = {
        'type': type,
        'token': token,
        'headquarter': headquarter,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': formattedTimestamp,
      };

      print('[DEBUG] AttendanceRepository: POST /turnouts');
      print('[DEBUG] AttendanceRepository: Body: $data');

      final response = await _dio.post(
        '/turnouts',
        data: data,
      );
      
      print('[DEBUG] AttendanceRepository: Response Status: ${response.statusCode}');
      print('[DEBUG] AttendanceRepository: Response Data: ${response.data}');

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      String errorMessage = 'No se pudo registrar la asistencia. Intente de nuevo.';
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['message']?.toString() ?? errorMessage;
      } else if (data is String && data.isNotEmpty) {
        errorMessage = data;
      }
      
      throw AttendanceException(errorMessage);
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
