import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

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
      final response = await _apiService.getMe();
      if (response.statusCode == 200) {
        _currentUser = UserModel.fromJson(response.data);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _currentUser = null;
      // We do not set error message here as it could just mean the session is expired/non-existent
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String username, String password, bool remember) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password, remember);
      if (response.statusCode == 200) {
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

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      // Ignored
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
