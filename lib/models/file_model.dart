class FileModel {
  final String filename;
  final String url;
  final String uploadedBy;
  final int? uploadedById;
  final String? uploadedByRole;
  final String? uploadedAt;
  final int? userId; // For archived files which return user_id
  final int? recipientId;
  final String? recipientName;

  FileModel({
    required this.filename,
    required this.url,
    required this.uploadedBy,
    this.uploadedById,
    this.uploadedByRole,
    this.uploadedAt,
    this.userId,
    this.recipientId,
    this.recipientName,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      uploadedBy: json['uploaded_by'] ?? 'غير معروف',
      uploadedById: json['uploaded_by_id'],
      uploadedByRole: json['uploaded_by_role'],
      uploadedAt: json['uploaded_at'],
      userId: json['user_id'],
      recipientId: json['recipient_id'],
      recipientName: json['recipient_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'uploaded_by': uploadedBy,
      'uploaded_by_id': uploadedById,
      'uploaded_by_role': uploadedByRole,
      'uploaded_at': uploadedAt,
      'user_id': userId,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
    };
  }

  // Helper to resolve dynamic download URL
  String getDownloadUrl(String baseUrl) {
    if (url.startsWith('http')) return url;
    final path = url.startsWith('/') ? url.substring(1) : url;
    return '$baseUrl/$path';
  }
}
