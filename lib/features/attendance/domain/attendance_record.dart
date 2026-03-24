/// Type of attendance event.
enum AttendanceType { entry, exit }

/// Domain model representing a single attendance event (entry or exit).
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.type,
    required this.dateTime,
    required this.employeeId,
  });

  final String id;
  final AttendanceType type;
  final DateTime dateTime;
  final String employeeId;
}
