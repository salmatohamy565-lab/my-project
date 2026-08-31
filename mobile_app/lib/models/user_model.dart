import 'dart:convert';
import 'package:flutter/widgets.dart';

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

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (username.trim().isNotEmpty) return username.trim();
    if (email != null && email!.trim().isNotEmpty) return email!.split('@').first.trim();
    return 'عميل بولا ديزاينز';
  }

  String getFullPhotoUrl(String baseUrl) {
    if (photoUrl == null || photoUrl!.trim().isEmpty) return '';
    final url = photoUrl!.trim();
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:image')) return url;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$cleanBase$cleanPath';
  }

  ImageProvider? getProfileImageProvider(String baseUrl) {
    if (photoUrl == null || photoUrl!.trim().isEmpty) return null;
    final url = photoUrl!.trim();
    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = url.substring(commaIndex + 1);
          final bytes = base64Decode(base64Str);
          return MemoryImage(bytes);
        }
      } catch (_) {
        return null;
      }
    }
    final fullUrl = getFullPhotoUrl(baseUrl);
    if (fullUrl.isNotEmpty) {
      return NetworkImage(fullUrl);
    }
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final photo = json['photo_url']?.toString() ??
        json['photo']?.toString() ??
        json['avatar']?.toString() ??
        json['profile_pic']?.toString() ??
        json['image']?.toString();

    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      name: json['name']?.toString() ?? json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      photoUrl: photo,
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
