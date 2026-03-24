import 'package:json_annotation/json_annotation.dart';

/// Model representing a completed attendance scan event.
@JsonSerializable()
class ScanResult {
  const ScanResult({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.qrData,
    required this.employeeId,
    required this.deviceInfo,
  });

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String qrData;
  final String employeeId;
  final String deviceInfo;

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        qrData: json['qrData'] as String,
        employeeId: json['employeeId'] as String,
        deviceInfo: json['deviceInfo'] as String,
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'qrData': qrData,
        'employeeId': employeeId,
        'deviceInfo': deviceInfo,
      };
}
