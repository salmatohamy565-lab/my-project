class AttendanceModel {
  final int id;
  final int userId;
  final String attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String status;
  final DateTime? createdAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.createdAt,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      attendanceDate: json['attendance_date'] ?? '',
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      status: json['status'] ?? 'present',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'attendance_date': attendanceDate,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
