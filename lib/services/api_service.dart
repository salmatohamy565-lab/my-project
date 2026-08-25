import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

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
    await prefs.remove('user_saved_orders');
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
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final pingDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ));
        final res = await pingDio.get('$_baseUrl/health');
        if (res.statusCode == 200) return;
      } catch (_) {
        if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
      }
    }
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
  Future<Response> getOrders({int? userId, String? userPhone, String? userName, bool? isStaff, String? status}) async {
    List<dynamic> resultOrders = [];

    try {
      var query = Supabase.instance.client.from('orders').select();

      if (isStaff != true && userId != null && userId > 0) {
        query = query.eq('user_id', userId);
      }

      final List<dynamic> sbData = await query.order('created_at', ascending: false).timeout(const Duration(seconds: 8));
      resultOrders = sbData;
    } catch (e) {
      print('[SUPABASE GET ORDERS ERROR] $e');
    }

    if (status != null && status != 'all' && status.isNotEmpty) {
      resultOrders = resultOrders.where((o) {
        final st = (o['status'] ?? '').toString().toLowerCase();
        if (status == 'pending' || status == 'pending_approval') {
          return st == 'pending' || st == 'pending_approval';
        }
        if (status == 'preparing') {
          return st == 'preparing' || st == 'in_progress' || st == 'processing' || st == 'approved';
        }
        if (status == 'ready') {
          return st == 'ready' || st == 'delivering';
        }
        if (status == 'delivered' || status == 'completed') {
          return st == 'delivered' || st == 'completed' || st == 'done';
        }
        if (status == 'rejected') {
          return st == 'rejected' || st == 'cancelled';
        }
        return st == status.toLowerCase();
      }).toList();
    }

    return Response(
      requestOptions: RequestOptions(path: '/orders'),
      statusCode: 200,
      data: resultOrders,
    );
  }

  Future<Response> createOrder({
    required dynamic productIds,
    String itemsSummary = '',
    List<dynamic>? itemsDetails,
    String paymentMethod = 'instapay',
    String? senderInfo,
    double totalPrice = 0.0,
    File? paymentProof,
    Uint8List? paymentProofBytes,
    String? paymentProofName,
    int? userId,
    String? userName,
    String? userPhone,
  }) async {
    String? proofUrl;
    if (paymentProofBytes != null || paymentProof != null) {
      try {
        final bytes = paymentProofBytes ?? await paymentProof!.readAsBytes();
        final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}_${paymentProofName ?? 'proof.jpg'}';
        try {
          await Supabase.instance.client.storage.from('payment-proofs').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          ).timeout(const Duration(seconds: 8));
          proofUrl = Supabase.instance.client.storage.from('payment-proofs').getPublicUrl(fileName);
        } catch (stErr) {
          final base64Str = base64Encode(bytes);
          proofUrl = 'data:image/jpeg;base64,$base64Str';
        }
      } catch (_) {}
    }

    try {
      final Map<String, dynamic> cleanPayload = {
        if (userId != null && userId > 0) 'user_id': userId,
        'customer_name': (userName != null && userName.isNotEmpty) ? userName : 'عميل',
        'customer_phone': userPhone ?? '',
        'product_ids': productIds.toString(),
        'items_summary': itemsSummary,
        'payment_method': paymentMethod,
        'total_price': totalPrice,
        'status': 'pending_approval',
        if (senderInfo != null && senderInfo.isNotEmpty) 'sender_info': senderInfo,
        if (senderInfo != null && senderInfo.isNotEmpty) 'customer_address': senderInfo,
        if (senderInfo != null && senderInfo.isNotEmpty) 'notes': senderInfo,
        if (proofUrl != null && proofUrl.isNotEmpty) 'payment_proof_url': proofUrl,
        'payment_proof_filename': 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
        'created_at': DateTime.now().toIso8601String(),
      };

      Map<String, dynamic> insertedObj;
      try {
        final extendedPayload = Map<String, dynamic>.from(cleanPayload);
        if (itemsDetails != null && itemsDetails.isNotEmpty) {
          extendedPayload['items_json'] = jsonEncode(itemsDetails);
        }

        insertedObj = await Supabase.instance.client
            .from('orders')
            .insert(extendedPayload)
            .select()
            .single()
            .timeout(const Duration(seconds: 10));
      } catch (schemaErr) {
        print('[SUPABASE INSERT NOTICE] Retrying with clean payload: $schemaErr');
        insertedObj = await Supabase.instance.client
            .from('orders')
            .insert(cleanPayload)
            .select()
            .single()
            .timeout(const Duration(seconds: 10));
      }

      final newOrderId = insertedObj['id'];

      // Insert Supabase Notifications for Customer and Admin
      try {
        await Supabase.instance.client.from('notifications').insert([
          {
            'order_id': newOrderId,
            if (userId != null && userId > 0) 'user_id': userId,
            'title': '🛒 تم إرسال طلبك بنجاح #$newOrderId',
            'message': 'طلبك بقيمة ${totalPrice.toStringAsFixed(0)} ج.م قيد المراجعة والمتابعة الآن.',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'order_id': newOrderId,
            'user_id': 0, // Broadcast for Admin/Owner
            'title': '📢 طلب جديد #$newOrderId',
            'message': 'وصل طلب جديد من ${userName ?? "عميل"} بقيمة ${totalPrice.toStringAsFixed(0)} ج.م',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          }
        ]).timeout(const Duration(seconds: 5));
      } catch (notifErr) {
        print('[SUPABASE CREATE ORDER NOTIF NOTICE] $notifErr');
      }

      try {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.vibrate();
      } catch (_) {}

      return Response(
        requestOptions: RequestOptions(path: '/orders'),
        statusCode: 201,
        data: insertedObj,
      );
    } catch (e) {
      print('[SUPABASE INSERT ORDER ERROR] $e');
      throw Exception('تعذر تسجيل الطلب في قاعدة البيانات: $e');
    }
  }

  Future<Response> updateOrderStatus(int orderId, String status, {String? reason, int? userId}) async {
    try {
      await Supabase.instance.client.from('orders').update({
        'status': status,
        if (reason != null) 'rejection_reason': reason,
      }).eq('id', orderId).timeout(const Duration(seconds: 8));

      // Build notification details for user
      String title = 'تحديث حالة الطلب #$orderId';
      String message = 'تم تحديث حالة طلبك إلى $status';
      if (status == 'preparing' || status == 'approved' || status == 'processing') {
        title = '🎉 تمت الموافقة على طلبك #$orderId';
        message = 'تمت الموافقة على طلبك رقم #$orderId وجاري تجهيزه الآن!';
      } else if (status == 'rejected') {
        title = '❌ تم رفض طلبك #$orderId';
        message = 'تم رفض الطلب رقم #$orderId. السبب: ${reason ?? "يرجى مراجعة تفاصيل الطلب"}';
      } else if (status == 'ready' || status == 'delivering') {
        title = '🚚 طلبك #$orderId جاهز للتوصيل';
        message = 'طلبك رقم #$orderId أصبح جاهزاً وسوف يتم شحنه إليك قريباً!';
      } else if (status == 'delivered' || status == 'completed') {
        title = '✅ تم تسليم الطلب #$orderId';
        message = 'تم تسليم طلبك رقم #$orderId بنجاح. شكراً لتسوقك من Bola Designs!';
      }

      try {
        await Supabase.instance.client.from('notifications').insert({
          'order_id': orderId,
          if (userId != null && userId > 0) 'user_id': userId,
          'title': title,
          'message': message,
          'created_at': DateTime.now().toIso8601String(),
        }).timeout(const Duration(seconds: 5));
      } catch (notifErr) {
        print('[SUPABASE NOTIFICATION INSERT NOTICE] $notifErr');
      }

      print('[SUPABASE UPDATE ORDER SUCCESS] Updated order #$orderId to status $status');
    } catch (e) {
      print('[SUPABASE UPDATE ORDER ERROR] $e');
      throw Exception('فشل تحديث حالة الطلب في Supabase: $e');
    }

    return Response(
      requestOptions: RequestOptions(path: '/orders/$orderId/status'),
      statusCode: 200,
      data: {'message': 'تم تحديث حالة الطلب بنجاح'},
    );
  }

  Future<Response> sendPasswordResetOtp(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (_) {}
    return Response(
      requestOptions: RequestOptions(path: '/auth/forget-password'),
      statusCode: 200,
      data: {'message': 'تم إرسال رمز استعادة كلمة المرور'},
    );
  }

  Future<Response> verifyOtpAndResetPassword(String email, String code, String newPassword) async {
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (_) {}
    return Response(
      requestOptions: RequestOptions(path: '/auth/reset-password'),
      statusCode: 200,
      data: {'message': 'تم تغيير كلمة المرور بنجاح'},
    );
  }

  // Notifications APIs
  Future<Response> getNotifications({int? userId}) async {
    try {
      var query = Supabase.instance.client.from('notifications').select();
      if (userId != null && userId > 0) {
        query = query.or('user_id.eq.$userId,user_id.is.null,user_id.eq.0');
      }
      final List<dynamic> sbData = await query.order('created_at', ascending: false).timeout(const Duration(seconds: 5));
      return Response(
        requestOptions: RequestOptions(path: '/notifications'),
        statusCode: 200,
        data: sbData,
      );
    } catch (e) {
      print('[SUPABASE GET NOTIFICATIONS ERROR] $e');
      return Response(
        requestOptions: RequestOptions(path: '/notifications'),
        statusCode: 200,
        data: [],
      );
    }
  }

  Future<Response> markNotificationsRead() async {
    return Response(
      requestOptions: RequestOptions(path: '/notifications/mark-read'),
      statusCode: 200,
      data: {'message': 'تمت القراءة'},
    );
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

  // Categories & Subcategories
  Future<List<Map<String, dynamic>>> getCategoriesFromSupabase() async {
    try {
      final categoriesData = await Supabase.instance.client
          .from('categories')
          .select('*, subcategories(*)')
          .order('id', ascending: true);
      return List<Map<String, dynamic>>.from(categoriesData);
    } catch (e) {
      print('[API SERVICE] Supabase getCategories error: $e');
      return [];
    }
  }

  // Products
  Future<Response> getProducts() async {
    try {
      final List<dynamic> sbData = await Supabase.instance.client
          .from('products')
          .select()
          .order('id', ascending: true);

      return Response(
        requestOptions: RequestOptions(path: '/products'),
        statusCode: 200,
        data: sbData,
      );
    } catch (e) {
      print('[API SERVICE] Supabase getProducts query failed: $e');
      return Response(
        requestOptions: RequestOptions(path: '/products'),
        statusCode: 200,
        data: [],
      );
    }
  }

  Future<Response> createProduct(
    String name,
    String description,
    double price,
    File? imageFile, {
    int? categoryId,
    int? subcategoryId,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null && imageFile.existsSync()) {
        try {
          final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final bytes = await imageFile.readAsBytes();
          await Supabase.instance.client.storage
              .from('product_images')
              .uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));

          imageUrl = Supabase.instance.client.storage
              .from('product_images')
              .getPublicUrl(fileName);
        } catch (uploadErr) {
          print('[SUPABASE STORAGE UPLOAD NOTICE] $uploadErr');
          imageUrl = imageFile.path.split('/').last.split('\\').last;
        }
      }

      final Map<String, dynamic> insertData = {
        'name': name,
        'description': description,
        'price': price,
        if (imageUrl != null && imageUrl.isNotEmpty) ...{
          'image_url': imageUrl,
          'image_filename': imageUrl,
        },
        'created_at': DateTime.now().toIso8601String(),
      };

      if (subcategoryId != null) {
        insertData['subcategory_id'] = subcategoryId;
        insertData['category_id'] = null;
      } else if (categoryId != null) {
        insertData['category_id'] = categoryId;
        insertData['subcategory_id'] = null;
      }

      final res = await Supabase.instance.client
          .from('products')
          .insert(insertData)
          .select()
          .single();

      return Response(
        requestOptions: RequestOptions(path: '/products'),
        statusCode: 201,
        data: res,
      );
    } catch (e) {
      print('[API SERVICE] Supabase createProduct failed: $e');
      throw Exception('فشل حفظ المنتج: $e');
    }
  }

  Future<Response> updateProduct(
    int productId,
    String name,
    String description,
    double price,
    File? imageFile, {
    int? categoryId,
    int? subcategoryId,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null && imageFile.existsSync()) {
        try {
          final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final bytes = await imageFile.readAsBytes();
          await Supabase.instance.client.storage
              .from('product_images')
              .uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));

          imageUrl = Supabase.instance.client.storage
              .from('product_images')
              .getPublicUrl(fileName);
        } catch (uploadErr) {
          print('[SUPABASE STORAGE UPLOAD NOTICE] $uploadErr');
          imageUrl = imageFile.path.split('/').last.split('\\').last;
        }
      }

      final Map<String, dynamic> updateData = {
        'name': name,
        'description': description,
        'price': price,
        if (imageUrl != null && imageUrl.isNotEmpty) ...{
          'image_url': imageUrl,
          'image_filename': imageUrl,
        },
      };

      if (subcategoryId != null) {
        updateData['subcategory_id'] = subcategoryId;
        updateData['category_id'] = null;
      } else if (categoryId != null) {
        updateData['category_id'] = categoryId;
        updateData['subcategory_id'] = null;
      }

      final res = await Supabase.instance.client
          .from('products')
          .update(updateData)
          .eq('id', productId)
          .select()
          .single();

      return Response(
        requestOptions: RequestOptions(path: '/products/$productId'),
        statusCode: 200,
        data: res,
      );
    } catch (e) {
      print('[API SERVICE] Supabase updateProduct failed: $e');
      throw Exception('فشل تعديل المنتج: $e');
    }
  }

  Future<Response> deleteProduct(int productId) async {
    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', productId);

      return Response(
        requestOptions: RequestOptions(path: '/products/$productId'),
        statusCode: 200,
        data: {'message': 'تم حذف المنتج بنجاح'},
      );
    } catch (e) {
      print('[API SERVICE] Supabase deleteProduct failed: $e');
      throw Exception('فشل حذف المنتج: $e');
    }
  }

  Future<Response> getPublicProducts() async {
    try {
      final response = await _dio.get('/public/products');
      if (response.statusCode == 200 && response.data != null && (response.data as List).isNotEmpty) {
        return response;
      }
    } catch (_) {}
    return getProducts();
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
