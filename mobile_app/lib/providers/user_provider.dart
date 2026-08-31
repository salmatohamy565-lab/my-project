import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/file_model.dart';
import '../models/attendance_model.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<UserModel> _users = [];
  Map<String, dynamic> _stats = {};
  List<FileModel> _userFiles = [];
  List<FileModel> _archivedFiles = [];
  List<AttendanceModel> _userAttendance = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  Map<String, dynamic> get stats => _stats;
  List<FileModel> get userFiles => _userFiles;
  List<FileModel> get archivedFiles => _archivedFiles;
  List<AttendanceModel> get userAttendance => _userAttendance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getUsers();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _users = data.map((json) => UserModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getDashboardStats();
      if (response.statusCode == 200) {
        _stats = response.data;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createUser(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createUser(username, password);
      if (response.statusCode == 201) {
        _isLoading = false;
        await fetchUsers();
        await fetchStats();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteUser(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteUser(userId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _users.removeWhere((u) => u.id == userId);
        _isLoading = false;
        notifyListeners();
        await fetchUsers();
        await fetchStats();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _users.removeWhere((u) => u.id == userId);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Attendance management
  Future<void> fetchUserAttendance(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getUserAttendance(userId);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _userAttendance = data.map((json) => AttendanceModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveAttendance(int userId, String attendanceDate, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.saveAttendance(userId, attendanceDate, status);
      if (response.statusCode == 201) {
        _isLoading = false;
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // File management
  Future<void> fetchUserFiles(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getUserFiles(userId);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _userFiles = data.map((json) => FileModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> uploadUserFile(
    int userId, {
    File? file,
    Uint8List? fileBytes,
    String? fileName,
    int? recipientId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.uploadUserFile(
        userId,
        file: file,
        fileBytes: fileBytes,
        fileName: fileName,
        recipientId: recipientId,
      );
      if (response.statusCode == 201) {
        _isLoading = false;
        await fetchUserFiles(userId);
        await fetchStats();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> toggleFileArchive(int userId, String filename, bool archive) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.archiveUserFile(userId, filename, archive);
      if (response.statusCode == 200) {
        _isLoading = false;
        await fetchUserFiles(userId);
        await fetchStats();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchArchivedFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getArchivedFiles();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _archivedFiles = data.map((json) => FileModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> exportArchivedFilesCsv() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.exportArchivedFilesCsv();
      if (response.statusCode == 200) {
        _isLoading = false;
        return response.data as String;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }
}
