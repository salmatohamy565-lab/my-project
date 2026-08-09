import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();
  static String get defaultBaseUrl {
    return 'https://bola-designs-backend.onrender.com';
  }

  static const String _defaultProdUrl = 'https://bola-designs-backend.onrender.com';
  String _baseUrl = defaultBaseUrl;
  String? _cookie;
  String? _token;

  String get baseUrl => _baseUrl;
  String? get cookie => _cookie;
  String? get token => _token;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = '$_baseUrl/api';
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        if (_cookie != null) {
          options.headers['Cookie'] = _cookie;
        }
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        final cookies = response.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          final newCookie = cookies.map((c) => c.split(';').first).join('; ');
          _cookie = newCookie;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_cookie', newCookie);
        }
        return handler.next(response);
      },
      onError: (DioException err, handler) async {
        return handler.next(err);
      },
    ));
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUrl = prefs.getString('api_base_url');
    if (storedUrl != null &&
        storedUrl.isNotEmpty &&
        !storedUrl.contains('127.0.0.1') &&
        !storedUrl.contains('localhost') &&
        !storedUrl.contains('10.0.2.2') &&
        !storedUrl.contains('192.168') &&
        !storedUrl.contains('5001')) {
      _baseUrl = storedUrl;
    } else {
      _baseUrl = defaultBaseUrl;
      await prefs.setString('api_base_url', _baseUrl);
    }
    _cookie = prefs.getString('session_cookie');
    _token = await _secureStorage.read(key: 'jwt_token');
    print('[API SERVICE INIT] Base URL resolved to: $_baseUrl');
  }

  Future<void> saveToken(String jwtToken) async {
    _token = jwtToken;
    await _secureStorage.write(key: 'jwt_token', value: jwtToken);
  }

  Future<void> setBaseUrl(String url) async {
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
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
    await _secureStorage.delete(key: 'jwt_token');
  }

  Future<void> _ensureWorkingBaseUrl() async {
    // 1. Try currently configured _baseUrl first (allows Render cold start up to 20s)
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final pingDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));
        final res = await pingDio.get('$_baseUrl/health');
        if (res.statusCode == 200) return;
      } catch (_) {
        if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
      }
    }

    // 2. Try primary production URL if _baseUrl was set to something else
    if (_baseUrl != defaultBaseUrl) {
      try {
        final pingDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ));
        final res = await pingDio.get('$defaultBaseUrl/health');
        if (res.statusCode == 200) {
          _baseUrl = defaultBaseUrl;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('api_base_url', _baseUrl);
          return;
        }
      } catch (_) {}
    }

    // Default to production URL
    _baseUrl = defaultBaseUrl;
  }

  // Auth APIs
  Future<Response> register({
    required String email,
    required String password,
    required String name,
    String? username,
    String? phone,
  }) async {
    await _ensureWorkingBaseUrl();
    try {
      final uName = (username != null && username.trim().isNotEmpty)
          ? username.trim()
          : (email.contains('@') ? email.split('@').first : email.trim());

      final response = await _dio.post('/customer/register', data: {
        'username': uName,
        'email': email,
        'password': password,
        'full_name': name,
        'name': name,
        'phone': phone ?? '',
      });
      if (response.data != null && response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final response = await _dio.post('/auth/register', data: {
          'email': email,
          'password': password,
          'name': name,
        });
        if (response.data != null && response.data['token'] != null) {
          await saveToken(response.data['token']);
        }
        return response;
      }
      throw _handleError(e);
    }
  }

  Future<Response> login(String usernameOrEmail, String password, bool remember) async {
    await _ensureWorkingBaseUrl();
    try {
      final response = await _dio.post('/customer/login', data: {
        'username': usernameOrEmail,
        'password': password,
        'remember': remember,
      });
      if (response.data != null && response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final response = await _dio.post('/login', data: {
          'username': usernameOrEmail,
          'password': password,
          'remember': remember,
        });
        if (response.data != null && response.data['token'] != null) {
          await saveToken(response.data['token']);
        }
        return response;
      }
      throw _handleError(e);
    }
  }

  Future<Response> googleAuth(String idToken) async {
    try {
      final response = await _dio.post('/auth/google', data: {
        'id_token': idToken,
      });
      if (response.data != null && response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> forgetPassword(String email) async {
    await _ensureWorkingBaseUrl();
    final targetEndpoint = '$_baseUrl/api/auth/forget-password';
    print('[UI API REQUEST] Base URL resolved to: $_baseUrl');
    print('[UI API REQUEST] Sending Forgot Password request to: $targetEndpoint for email: $email');
    try {
      final response = await _dio.post('/auth/forget-password', data: {
        'email': email,
      });
      print('[UI API RESPONSE SUCCESS] Status: ${response.statusCode}, Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('[UI API RESPONSE ERROR] Status Code: ${e.response?.statusCode}, Message: ${e.message}, Data: ${e.response?.data}, ErrorType: ${e.type}');
      throw _handleError(e);
    } catch (e) {
      print('[UI API UNEXPECTED ERROR] $e');
      rethrow;
    }
  }

  Future<Response> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
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
      await clearSession();
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

  // Profile APIs
  Future<Response> getProfile() async {
    await _ensureWorkingBaseUrl();
    try {
      final response = await _dio.get('/profile');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> updateProfile({
    String? name,
    String? phone,
    File? photo,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    await _ensureWorkingBaseUrl();
    try {
      final Map<String, dynamic> map = {};
      if (name != null && name.trim().isNotEmpty) map['name'] = name.trim();
      if (phone != null && phone.trim().isNotEmpty) map['phone'] = phone.trim();

      if (photoBytes != null && photoBytes.isNotEmpty) {
        map['photo'] = MultipartFile.fromBytes(
          photoBytes,
          filename: photoName ?? 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else if (photo != null && !kIsWeb && photo.path.isNotEmpty) {
        final fileName = photo.path.split(photo.path.contains('\\') ? '\\' : '/').last;
        map['photo'] = await MultipartFile.fromFile(photo.path, filename: fileName);
      }

      if (map.containsKey('photo')) {
        final formData = FormData.fromMap(map);
        final response = await _dio.post(
          '/profile',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        return response;
      } else {
        final response = await _dio.post('/profile', data: map);
        return response;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Orders APIs
  Future<Response> getOrders({String? status}) async {
    await _ensureWorkingBaseUrl();
    try {
      final response = await _dio.get(
        '/orders',
        queryParameters: status != null && status != 'all' ? {'status': status} : null,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> createOrder({
    required dynamic productIds,
    String itemsSummary = '',
    String paymentMethod = 'instapay',
    double totalPrice = 0.0,
    File? paymentProof,
    Uint8List? paymentProofBytes,
    String? paymentProofName,
  }) async {
    await _ensureWorkingBaseUrl();

    Future<Response> doPost() async {
      final Map<String, dynamic> dataMap = {
        'product_ids': productIds.toString(),
        'items_summary': itemsSummary,
        'payment_method': paymentMethod,
        'total_price': totalPrice.toString(),
      };

      if (paymentProofBytes != null && paymentProofBytes.isNotEmpty) {
        dataMap['payment_proof'] = MultipartFile.fromBytes(
          paymentProofBytes,
          filename: paymentProofName ?? 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else if (paymentProof != null && !kIsWeb && paymentProof.path.isNotEmpty) {
        final fileName = paymentProof.path.split(paymentProof.path.contains('\\') ? '\\' : '/').last;
        dataMap['payment_proof'] = await MultipartFile.fromFile(paymentProof.path, filename: fileName);
      }

      if (dataMap.containsKey('payment_proof')) {
        final formData = FormData.fromMap(dataMap);
        return await _dio.post(
          '/orders',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
      } else {
        return await _dio.post('/orders', data: dataMap);
      }
    }

    try {
      return await doPost();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        await Future.delayed(const Duration(seconds: 2));
        try {
          return await doPost();
        } catch (retryErr) {
          if (retryErr is DioException) {
            throw _handleError(retryErr);
          }
        }
      }
      throw _handleError(e);
    }
  }

  Future<Response> updateOrderStatus(int orderId, String status, {String? reason}) async {
    try {
      final response = await _dio.put(
        '/orders/$orderId/status',
        data: {
          'status': status,
          if (reason != null) 'rejection_reason': reason,
        },
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Notifications APIs
  Future<Response> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> markNotificationsRead() async {
    try {
      final response = await _dio.put('/notifications/mark-read');
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

  Future<Response> uploadUserFile(
    int userId, {
    File? file,
    Uint8List? fileBytes,
    String? fileName,
    int? recipientId,
  }) async {
    try {
      MultipartFile multipartFile;
      if (kIsWeb && fileBytes != null && fileName != null) {
        multipartFile = MultipartFile.fromBytes(fileBytes, filename: fileName);
      } else if (file != null) {
        final name = fileName ?? file.path.split(file.path.contains('\\') ? '\\' : '/').last;
        multipartFile = await MultipartFile.fromFile(file.path, filename: name);
      } else {
        throw Exception('No file or file bytes provided');
      }

      final map = <String, dynamic>{
        'file': multipartFile,
      };
      if (recipientId != null) {
        map['recipient_id'] = recipientId;
      }
      final formData = FormData.fromMap(map);
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

  Future<Response> createProduct(String name, String description, double price, File? imageFile, {String? categoryId}) async {
    try {
      final Map<String, dynamic> dataMap = {
        'name': name,
        'description': description,
        'price': price.toString(),
        if (categoryId != null) 'category_id': categoryId,
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

  Future<Response> updateProduct(int productId, String name, String description, double price, File? imageFile, {String? categoryId}) async {
    try {
      final Map<String, dynamic> dataMap = {
        'name': name,
        'description': description,
        'price': price.toString(),
        if (categoryId != null) 'category_id': categoryId,
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
      message = 'عفواً، جاري الاتصال بالخادم، يرجى المحاولة مرة أخرى بعد لحظات';
    } else if (error.type == DioExceptionType.badResponse) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData.containsKey('error') && responseData['error'] != null) {
        message = responseData['error'].toString();
      } else {
        message = 'حدث خطأ من الخادم (${error.response?.statusCode ?? 500})، يرجى المحاولة لاحقاً';
      }
    } else if (error.error is SocketException) {
      message = 'يرجى التحقق من اتصال الانترنت والمحاولة مرة أخرى';
    } else if (error.message != null && error.message!.trim().isNotEmpty) {
      message = error.message!;
    }
    return Exception(message);
  }
}
