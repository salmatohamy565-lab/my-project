class TaskModel {
  final int id;
  final String title;
  final String description;
  final int assignedTo;
  final String? assignedToUsername;
  final String status;
  final DateTime? createdAt;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    this.assignedToUsername,
    required this.status,
    this.createdAt,
    this.completedAt,
  });

  bool get isDone => status == 'done';
  bool get isArchived => status == 'archived';
  bool get isPending => status == 'pending';

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedTo: json['assigned_to'] ?? 0,
      assignedToUsername: json['assigned_to_username'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_to_username': assignedToUsername,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
