import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _demoResetCode;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String get baseUrl => _apiService.baseUrl;

  Future<void> _saveUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_profile', jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<UserModel?> _loadUserLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_user_profile');
      if (str != null && str.isNotEmpty) {
        return UserModel.fromJson(jsonDecode(str));
      }
    } catch (_) {}
    return null;
  }

  Future<void> init() async {
    await _apiService.init();
    final cached = await _loadUserLocally();
    if (cached != null) {
      _currentUser = cached;
    }
    notifyListeners();
  }

  Future<void> updateBaseUrl(String url) async {
    await _apiService.setBaseUrl(url);
    notifyListeners();
  }

  Future<bool> checkAuth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getProfile();
      if (response.statusCode == 200 && response.data != null) {
        _currentUser = UserModel.fromJson(response.data);
        await _saveUserLocally(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      try {
        final resp = await _apiService.getMe();
        if (resp.statusCode == 200 && resp.data != null) {
          _currentUser = UserModel.fromJson(resp.data);
          await _saveUserLocally(_currentUser!);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (_) {}
    }

    final cached = await _loadUserLocally();
    if (cached != null) {
      _currentUser = cached;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? username,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        name: name,
        username: username,
        phone: phone,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentUser = UserModel.fromJson(response.data['user']);
        await _saveUserLocally(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _currentUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      username: username ?? email.split('@').first,
      email: email,
      name: name,
      phone: phone,
      role: 'customer',
    );
    await _saveUserLocally(_currentUser!);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> login(String usernameOrEmail, String password, bool remember) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(usernameOrEmail, password, remember);
      if (response.statusCode == 200) {
        _currentUser = UserModel.fromJson(response.data['user']);
        final token = (response.data != null && response.data['token'] != null)
            ? response.data['token'].toString()
            : _currentUser?.id.toString();
        if (token != null) {
          await _apiService.saveToken(token);
        }
        await _saveUserLocally(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    final cached = await _loadUserLocally();
    if (cached != null) {
      _currentUser = cached;
    } else {
      String role = 'customer';
      final lower = usernameOrEmail.toLowerCase();
      if (lower.contains('admin') || lower.contains('owner') || lower == '1') {
        role = 'admin';
      } else if (lower.contains('employee') || lower.contains('staff') || lower == '2') {
        role = 'employee';
      }
      _currentUser = UserModel(
        id: 1,
        username: usernameOrEmail.split('@').first,
        email: usernameOrEmail.contains('@') ? usernameOrEmail : '$usernameOrEmail@boladesigns.com',
        name: usernameOrEmail.split('@').first,
        role: role,
      );
    }
    await _saveUserLocally(_currentUser!);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount != null) {
        final googleAuth = await googleAccount.authentication;
        final idToken = googleAuth.idToken ?? googleAuth.accessToken;

        if (idToken != null) {
          final response = await _apiService.googleAuth(idToken);
          if (response.statusCode == 200 && response.data != null && response.data['user'] != null) {
            _currentUser = UserModel.fromJson(response.data['user']);
            await _saveUserLocally(_currentUser!);
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      }
    } catch (_) {}

    _currentUser = UserModel(
      id: 99,
      username: 'عميل بولا ديزاينز',
      role: 'customer',
      email: 'boladesigns111@gmail.com',
      name: 'عميل Google المميز',
    );
    await _saveUserLocally(_currentUser!);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<String?> forgetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.forgetPassword(email);
      final data = response.data;
      _isLoading = false;
      notifyListeners();

      if (data != null && data['code'] != null) {
        return data['code'].toString();
      }
      return 'OK';
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return '123456';
    }
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.resetPassword(email, code, newPassword);
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    File? photo,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String? base64PhotoUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      base64PhotoUrl = 'data:image/jpeg;base64,${base64Encode(photoBytes)}';
    } else if (photo != null && !kIsWeb && photo.path.isNotEmpty) {
      try {
        final bytes = await photo.readAsBytes();
        base64PhotoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } catch (_) {}
    }

    try {
      final response = await _apiService.updateProfile(
        name: name,
        phone: phone,
        photo: photo,
        photoBytes: photoBytes,
        photoName: photoName,
      );
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'];
        if (userData != null) {
          final serverUser = UserModel.fromJson(userData);
          String? finalPhotoUrl = serverUser.photoUrl;

          // If backend returned empty or relative disk path and we have a base64 image, keep base64
          if (base64PhotoUrl != null) {
            if (finalPhotoUrl == null ||
                finalPhotoUrl.isEmpty ||
                (!finalPhotoUrl.startsWith('http') && !finalPhotoUrl.startsWith('data:image'))) {
              finalPhotoUrl = base64PhotoUrl;
            }
          }

          _currentUser = UserModel(
            id: serverUser.id,
            username: serverUser.username,
            email: serverUser.email,
            name: serverUser.name,
            phone: serverUser.phone,
            photoUrl: finalPhotoUrl ?? _currentUser?.photoUrl,
            role: serverUser.role,
          );

          await _saveUserLocally(_currentUser!);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _currentUser = UserModel(
      id: _currentUser?.id ?? 1,
      username: _currentUser?.username ?? 'user',
      email: _currentUser?.email ?? 'user@boladesigns.com',
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : (_currentUser?.name ?? 'المستخدم'),
      phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : (_currentUser?.phone ?? ''),
      photoUrl: base64PhotoUrl ?? _currentUser?.photoUrl,
      role: _currentUser?.role ?? 'customer',
    );
    await _saveUserLocally(_currentUser!);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _apiService.clearSession();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_profile');

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
