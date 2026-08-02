import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();
  static const String _defaultProdUrl = 'https://bola-designs-backend.onrender.com';
  String _baseUrl = kReleaseMode ? _defaultProdUrl : _defaultProdUrl;
  String? _cookie;
  String? _token;

  String get baseUrl => _baseUrl;
  String? get cookie => _cookie;
  String? get token => _token;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio.options.connectTimeout = const Duration(seconds: 8);
    _dio.options.receiveTimeout = const Duration(seconds: 8);

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
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError ||
            err.error is SocketException) {
          
          final candidateUrls = [
            'https://bola-designs-backend.onrender.com',
            'http://192.168.1.18:5001',
            'http://10.0.2.2:5001',
            'http://localhost:5001',
          ];

          for (final candidate in candidateUrls) {
            if (candidate == _baseUrl) continue;
            try {
              final testDio = Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 2),
                receiveTimeout: const Duration(seconds: 2),
              ));
              final pingRes = await testDio.get('$candidate/api/public/products');
              if (pingRes.statusCode == 200) {
                await setBaseUrl(candidate);
                
                final RequestOptions opts = err.requestOptions;
                opts.baseUrl = '$_baseUrl/api';
                final clonedReq = await _dio.fetch(opts);
                return handler.resolve(clonedReq);
              }
            } catch (_) {}
          }
        }
        return handler.next(err);
      },
    ));
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = kIsWeb ? 'http://localhost:5001' : 'http://192.168.1.18:5001';
    String? storedUrl = prefs.getString('api_base_url');
    if (storedUrl != null &&
        storedUrl.isNotEmpty &&
        storedUrl.startsWith('http')) {
      _baseUrl = storedUrl;
    } else {
      await prefs.setString('api_base_url', _baseUrl);
    }
    _cookie = prefs.getString('session_cookie');
    _token = await _secureStorage.read(key: 'jwt_token');
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
    try {
      final pingDio = Dio(BaseOptions(
        connectTimeout: const Duration(milliseconds: 1500),
        receiveTimeout: const Duration(milliseconds: 1500),
      ));
      final res = await pingDio.get('$_baseUrl/api/public/products');
      if (res.statusCode == 200) return;
    } catch (_) {}

    final candidates = [
      'http://127.0.0.1:5001',
      'http://localhost:5001',
      'http://192.168.1.18:5001',
      'http://10.0.2.2:5001',
    ];

    for (final candidate in candidates) {
      if (candidate == _baseUrl) continue;
      try {
        final pingDio = Dio(BaseOptions(
          connectTimeout: const Duration(milliseconds: 1500),
          receiveTimeout: const Duration(milliseconds: 1500),
        ));
        final res = await pingDio.get('$candidate/api/public/products');
        if (res.statusCode == 200) {
          await setBaseUrl(candidate);
          return;
        }
      } catch (_) {}
    }
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
    try {
      final response = await _dio.post('/auth/forget-password', data: {
        'email': email,
      });
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
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
    try {
      final response = await _dio.get('/profile');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> updateProfile({String? name, String? phone, File? photo}) async {
    try {
      if (photo == null || kIsWeb) {
        final response = await _dio.post(
          '/profile',
          data: {
            if (name != null) 'name': name,
            if (phone != null) 'phone': phone,
          },
        );
        return response;
      }

      final Map<String, dynamic> map = {};
      if (name != null) map['name'] = name;
      if (phone != null) map['phone'] = phone;

      final fileName = photo.path.split(photo.path.contains('\\') ? '\\' : '/').last;
      map['photo'] = await MultipartFile.fromFile(photo.path, filename: fileName);

      final formData = FormData.fromMap(map);
      final response = await _dio.post(
        '/profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Orders APIs
  Future<Response> getOrders({String? status}) async {
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
    try {
      final Map<String, dynamic> dataMap = {
        'product_ids': productIds.toString(),
        'items_summary': itemsSummary,
        'payment_method': paymentMethod,
        'total_price': totalPrice.toString(),
      };

      if (paymentProofBytes != null && paymentProofName != null && paymentProofName.isNotEmpty) {
        dataMap['payment_proof'] = MultipartFile.fromBytes(
          paymentProofBytes,
          filename: paymentProofName,
        );
      } else if (paymentProof != null && paymentProof.path.isNotEmpty) {
        final fileName = paymentProof.path.split(paymentProof.path.contains('\\') ? '\\' : '/').last;
        dataMap['payment_proof'] = await MultipartFile.fromFile(paymentProof.path, filename: fileName);
      }

      final formData = FormData.fromMap(dataMap);
      final response = await _dio.post(
        '/orders',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } on DioException catch (e) {
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
