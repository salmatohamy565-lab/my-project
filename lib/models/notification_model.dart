class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      userId: json['user_id'] is int ? json['user_id'] : (int.tryParse(json['user_id']?.toString() ?? '') ?? 0),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == 'true',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
