import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  String _baseUrl = kIsWeb ? 'http://localhost:5001' : 'http://127.0.0.1:5001';
  String? _cookie;

  String get baseUrl => _baseUrl;
  String? get cookie => _cookie;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Interceptor to manage Cookies and dynamic base URLs
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.baseUrl = '$_baseUrl/api';
        if (_cookie != null) {
          options.headers['Cookie'] = _cookie;
        }
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        // Extract Set-Cookie header to persist Flask session
        final cookies = response.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          // Join multiple cookies if any, separated by semicolon
          final newCookie = cookies.map((c) => c.split(';').first).join('; ');
          _cookie = newCookie;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_cookie', newCookie);
        }
        return handler.next(response);
      },
    ));
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUrl = prefs.getString('api_base_url');
    if (storedUrl == null || storedUrl.contains('192.168.1.19') || storedUrl == 'http://10.0.2.2:5001') {
      _baseUrl = kIsWeb ? 'http://localhost:5001' : 'http://127.0.0.1:5001';
      await prefs.setString('api_base_url', _baseUrl);
    } else {
      _baseUrl = storedUrl;
    }
    _cookie = prefs.getString('session_cookie');
  }

  Future<void> setBaseUrl(String url) async {
    // Standardize URL (remove trailing slash)
    String cleanedUrl = url.trim();
    if (cleanedUrl.endsWith('/')) {
      cleanedUrl = cleanedUrl.substring(0, cleanedUrl.length - 1);
    }
    _baseUrl = cleanedUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', cleanedUrl);
  }

  Future<void> clearSession() async {
    _cookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
  }

  // Auth APIs
  Future<Response> login(String username, String password, bool remember) async {
    try {
      final response = await _dio.post('/login', data: {
        'username': username,
        'password': password,
        'remember': remember,
      });
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> logout() async {
    try {
      final response = await _dio.post('/logout');
      await clearSession();
      return response;
    } on DioException catch (e) {
      await clearSession(); // Force clear local session even if api fails
      throw _handleError(e);
    }
  }

  Future<Response> getMe() async {
    try {
      final response = await _dio.get('/me');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Dashboard Stats
  Future<Response> getDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard/stats');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Users Management
  Future<Response> getUsers() async {
    try {
      final response = await _dio.get('/users');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> createUser(String username, String password) async {
    try {
      final response = await _dio.post('/users', data: {
        'username': username,
        'password': password,
        'role': 'supervisor',
      });
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> deleteUser(int userId) async {
    try {
      final response = await _dio.delete('/users/$userId');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Attendance
  Future<Response> getUserAttendance(int userId) async {
    try {
      final response = await _dio.get('/users/$userId/attendance');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> saveAttendance(int userId, String attendanceDate, String status) async {
    try {
      final response = await _dio.post('/attendance', data: {
        'user_id': userId,
        'attendance_date': attendanceDate,
        'status': status,
      });
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Tasks
  Future<Response> getTasks() async {
    try {
      final response = await _dio.get('/tasks');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> createTask(String title, String description, int assignedTo) async {
    try {
      final response = await _dio.post('/tasks', data: {
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
      });
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getArchivedTasks() async {
    try {
      final response = await _dio.get('/tasks/archived');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> archiveTasksNow() async {
    try {
      final response = await _dio.post('/tasks/archive');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> markTaskDone(int taskId) async {
    try {
      final response = await _dio.put('/tasks/$taskId/done');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // User Files
  Future<Response> getUserFiles(int userId) async {
    try {
      final response = await _dio.get('/users/$userId/files');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadUserFile(int userId, File file) async {
    try {
      final fileName = file.path.split(file.path.contains('\\') ? '\\' : '/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _dio.post(
        '/users/$userId/files',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> archiveUserFile(int userId, String filename, bool archived) async {
    try {
      final response = await _dio.post(
        '/users/$userId/files/$filename/archive',
        data: {'archived': archived},
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getArchivedFiles() async {
    try {
      final response = await _dio.get('/files/archived');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> exportArchivedFilesCsv() async {
    try {
      final response = await _dio.get(
        '/files/archived/export',
        options: Options(responseType: ResponseType.plain),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Products
  Future<Response> getProducts() async {
    try {
      final response = await _dio.get('/products');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> createProduct(String name, String description, double price, File? imageFile) async {
    try {
      final Map<String, dynamic> dataMap = {
        'name': name,
        'description': description,
        'price': price.toString(),
      };
      
      if (imageFile != null) {
        final fileName = imageFile.path.split(imageFile.path.contains('\\') ? '\\' : '/').last;
        dataMap['image'] = await MultipartFile.fromFile(imageFile.path, filename: fileName);
      }

      final formData = FormData.fromMap(dataMap);
      final response = await _dio.post(
        '/products',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> updateProduct(int productId, String name, String description, double price, File? imageFile) async {
    try {
      final Map<String, dynamic> dataMap = {
        'name': name,
        'description': description,
        'price': price.toString(),
      };
      
      if (imageFile != null) {
        final fileName = imageFile.path.split(imageFile.path.contains('\\') ? '\\' : '/').last;
        dataMap['image'] = await MultipartFile.fromFile(imageFile.path, filename: fileName);
      }

      final formData = FormData.fromMap(dataMap);
      final response = await _dio.put(
        '/products/$productId',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> deleteProduct(int productId) async {
    try {
      final response = await _dio.delete('/products/$productId');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getPublicProducts() async {
    try {
      // The public catalog endpoint doesn't require prefixing with /api in backend,
      // but in Flask we defined it as: @app.route('/api/public/products', methods=['GET'])
      // Wait, let's verify if public products uses /api.
      // Yes! Line 624 in بولا.py: @app.route('/api/public/products', methods=['GET'])
      // So we can use /public/products relative to options.baseUrl (which is /api)
      final response = await _dio.get('/public/products');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handler Utility
  Exception _handleError(DioException error) {
    String message = 'حدث خطأ غير متوقع';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'انتهت مهلة الاتصال بالخادم، يرجى التحقق من الشبكة';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'فشل الاتصال بالخادم، تأكد أن IP الخادم صحيح والخادم يعمل';
    } else if (error.type == DioExceptionType.badResponse) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData.containsKey('error') && responseData['error'] != null) {
        message = responseData['error'].toString();
      } else {
        message = 'بيانات الدخول غير صحيحة أو خطأ من الخادم (${error.response?.statusCode ?? 500})';
      }
    } else if (error.error is SocketException) {
      message = 'فشل الاتصال بالخادم، تأكد أن العنوان صحيح والخادم يعمل';
    } else if (error.message != null && error.message!.trim().isNotEmpty) {
      message = error.message!;
    }
    return Exception(message);
  }
}
