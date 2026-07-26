class UserModel {
  final int id;
  final String username;
  final String? email;
  final String? name;
  final String? phone;
  final String? photoUrl;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.name,
    this.phone,
    this.photoUrl,
    required this.role,
  });

  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get isEmployee => role == 'employee';
  bool get isCustomer => !isAdmin && !isEmployee;

  String get displayName => (name != null && name!.trim().isNotEmpty) ? name! : username;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      role: json['role']?.toString() ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'phone': phone,
      'photo_url': photoUrl,
      'role': role,
    };
  }
}
