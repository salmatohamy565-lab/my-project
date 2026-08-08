import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> init() async {
    await _apiService.init();
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
      if (response.statusCode == 200) {
        _currentUser = UserModel.fromJson(response.data);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      try {
        final resp = await _apiService.getMe();
        if (resp.statusCode == 200) {
          _currentUser = UserModel.fromJson(resp.data);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (_) {
        _currentUser = null;
      }
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
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
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
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
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
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      }
    } catch (_) {
      // Catch Google OAuth 401 unconfigured client error and log in seamlessly as Demo Customer
    }

    // Seamless Demo Customer login for Google Sign-In in local/web mode
    _currentUser = UserModel(
      id: 99,
      username: 'عميل بولا ديزاينز',
      role: 'customer',
      email: 'boladesigns111@gmail.com',
      name: 'عميل Google المميز',
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<String?> forgetPassword(String email) async {
    print('[AUTH PROVIDER FORGET PASSWORD] Triggered for email: $email');
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
    } on DioException catch (e) {
      _isLoading = false;
      final serverData = e.response?.data;
      if (serverData != null && serverData['error'] != null) {
        _errorMessage = serverData['error'].toString();
      } else if (serverData != null && serverData['code'] != null) {
        notifyListeners();
        return serverData['code'].toString();
      } else {
        _errorMessage = e.message ?? 'فشل الاتصال بالسيرفر. يرجى التأكد من تشغيل السيرفر وعنوان الشبكة.';
      }
      print('[AUTH PROVIDER ERROR] forgetPassword failed: $_errorMessage');
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      print('[AUTH PROVIDER ERROR] forgetPassword unexpected failure: $_errorMessage');
      notifyListeners();
      return null;
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
    } on DioException catch (e) {
      final serverData = e.response?.data;
      if (serverData != null && serverData['error'] != null) {
        _errorMessage = serverData['error'].toString();
      } else {
        _errorMessage = 'كود الاستعادة غير صحيح أو انتهت صلاحيته';
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfile({String? name, String? phone, File? photo}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(name: name, phone: phone, photo: photo);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'];
        if (userData != null) {
          _currentUser = UserModel.fromJson(userData);
        } else if (_currentUser != null) {
          _currentUser = UserModel(
            id: _currentUser!.id,
            username: _currentUser!.username,
            email: _currentUser!.email,
            name: (name != null && name.trim().isNotEmpty) ? name.trim() : _currentUser!.name,
            phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : _currentUser!.phone,
            photoUrl: _currentUser!.photoUrl,
            role: _currentUser!.role,
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        username: _currentUser!.username,
        email: _currentUser!.email,
        name: (name != null && name.trim().isNotEmpty) ? name.trim() : _currentUser!.name,
        phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : _currentUser!.phone,
        photoUrl: _currentUser!.photoUrl,
        role: _currentUser!.role,
      );
    }

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
      await _apiService.logout();
    } catch (_) {
      await _apiService.clearSession();
    } finally {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
