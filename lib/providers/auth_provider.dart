import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      await prefs.setBool('is_user_logged_in', true);
    } catch (_) {}
  }

  Future<UserModel?> _loadUserLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_user_logged_in') ?? false;
      final str = prefs.getString('cached_user_profile');
      if (isLoggedIn && str != null && str.isNotEmpty) {
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

    // 1. Check persistent local session first
    final cached = await _loadUserLocally();
    if (cached != null) {
      _currentUser = cached;
      _isLoading = false;
      notifyListeners();

      // Refresh profile silently in background
      _apiService.getProfile().then((response) {
        if (response.statusCode == 200 && response.data != null) {
          final updated = UserModel.fromJson(response.data);
          if (updated.id == _currentUser?.id || (updated.email != null && updated.email == _currentUser?.email)) {
            _currentUser = updated;
            _saveUserLocally(_currentUser!);
            notifyListeners();
          }
        }
      }).catchError((_) {});

      return true;
    }

    // 2. Fallback check with server
    try {
      final response = await _apiService.getProfile().timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 && response.data != null) {
        _currentUser = UserModel.fromJson(response.data);
        await _saveUserLocally(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

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
        if (response.data != null && response.data['user'] != null) {
          _currentUser = UserModel.fromJson(response.data['user']);
          await _saveUserLocally(_currentUser!);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _errorMessage = 'تعذر إنشاء الحساب، يرجى المحاولة مرة أخرى';
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
        await _saveUserLocally(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _errorMessage = 'اسم المستخدم أو البريد أو كلمة السر غير صحيحة';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> phoneLogin(String username, String phone, bool remember) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client.rpc(
        'passwordless_login',
        params: {'p_username': username.trim(), 'p_phone': phone.trim()},
      );

      if (res != null && res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user']);
        await _saveUserLocally(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      final str = e.toString();
      if (str.contains('423') || str.contains('15 دقيقة')) {
        _errorMessage = 'تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة';
      } else {
        _errorMessage = 'اسم المستخدم أو رقم الهاتف غير صحيح';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _errorMessage = 'اسم المستخدم أو رقم الهاتف غير صحيح';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> passwordlessRegister(String username, String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await Supabase.instance.client.rpc(
        'passwordless_register',
        params: {'p_username': username.trim(), 'p_phone': phone.trim()},
      );

      if (res != null && res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user']);
        await _saveUserLocally(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      final str = e.toString();
      if (str.contains('مسجل بالفعل')) {
        _errorMessage = 'اسم المستخدم مسجل بالفعل، يرجى اختيار اسم آخر';
      } else {
        _errorMessage = 'حدث خطأ أثناء إنشاء الحساب، يرجى التأكد من البيانات';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _errorMessage = 'تعذر إنشاء الحساب، يرجى إعادة المحاولة';
    _isLoading = false;
    notifyListeners();
    return false;
  }






  static String extractUsernameFromEmail(String email) {
    if (email.isEmpty) return '';
    final clean = email.trim();
    if (!clean.contains('@')) return clean;

    final prefix = clean.split('@').first;
    final parts = prefix.split(RegExp(r'[._\d-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.first;
    }
    return prefix;
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
          try {
            final response = await _apiService.googleAuth(idToken);
            if (response.statusCode == 200 && response.data != null && response.data['user'] != null) {
              _currentUser = UserModel.fromJson(response.data['user']);
              await _saveUserLocally(_currentUser!);
              _isLoading = false;
              notifyListeners();
              return true;
            }
          } catch (_) {}
        }

        final gEmail = googleAccount.email;
        final extractedUsername = extractUsernameFromEmail(gEmail);
        final gName = (googleAccount.displayName != null && googleAccount.displayName!.isNotEmpty)
            ? googleAccount.displayName!
            : extractedUsername;
        _currentUser = UserModel(
          id: 999,
          username: extractedUsername.isNotEmpty ? extractedUsername : gEmail.split('@').first,
          role: 'customer',
          email: gEmail,
          name: gName,
        );
        await _saveUserLocally(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _currentUser = UserModel(
      id: 999,
      username: 'customer',
      role: 'customer',
      email: 'customer@gmail.com',
      name: 'customer',
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
      await _apiService.sendPasswordResetOtp(email);
      _isLoading = false;
      notifyListeners();
      return 'OK';
    } on AuthException catch (e) {
      if (e.message.contains('User not found') || e.statusCode == '404' || e.code == 'user_not_found') {
        _errorMessage = 'عفواً، لا يوجد حساب مرتبط بهذا البريد الإلكتروني على Supabase.';
      } else {
        _errorMessage = e.message;
      }
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إرسال كود الاستعادة: ${e.toString().replaceFirst('Exception: ', '')}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyOtpAndResetPassword(email, code, newPassword);
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'كود التحقق غير صحيح أو انتهت صلاحيته.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إعادة تعيين كلمة السر: ${e.toString().replaceFirst('Exception: ', '')}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
    await prefs.remove('user_saved_orders');
    await prefs.setBool('is_user_logged_in', false);

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
