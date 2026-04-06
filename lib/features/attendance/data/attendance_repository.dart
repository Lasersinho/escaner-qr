import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

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
      // Create FormData for multipart upload
      final formData = FormData.fromMap(result.toJson());

      // Append files if paths exist
      if (result.backPhotoPath != null) {
        formData.files.add(MapEntry(
          'backPhoto',
          await MultipartFile.fromFile(result.backPhotoPath!, filename: 'backPhoto.jpg'),
        ));
      }
      if (result.frontPhotoPath != null) {
        formData.files.add(MapEntry(
          'frontPhoto',
          await MultipartFile.fromFile(result.frontPhotoPath!, filename: 'frontPhoto.jpg'),
        ));
      }

      final response = await _dio.post(
        '/departure',
        data: formData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw AttendanceException(
        e.response?.data?['message']?.toString() ??
            'No se pudo registrar la salida. Intente de nuevo.',
      );
    }
  }

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

      final response = await _dio.post(
        '/turnouts',
        data: data,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw AttendanceException(
        e.response?.data?['message']?.toString() ??
            'No se pudo registrar la asistencia. Intente de nuevo.',
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
