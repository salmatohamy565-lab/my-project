import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:intl/intl.dart';

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
    // Direct Supabase mode: No external REST ping needed.
    return;
  }

  // Auth APIs
  Future<Response> register({
    required String email,
    required String password,
    required String name,
    String? username,
    String? phone,
  }) async {
    try {
      final uName = (username != null && username.trim().isNotEmpty)
          ? username.trim()
          : (email.contains('@') ? email.split('@').first : email.trim());

      final inserted = await Supabase.instance.client
          .from('users')
          .insert({
            'username': uName,
            'email': email.trim(),
            'password_hash': password.trim(),
            'name': name.trim(),
            'phone': phone?.trim() ?? '',
            'role': 'customer',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 10));

      final token = inserted['id'].toString();
      await saveToken(token);

      return Response(
        requestOptions: RequestOptions(path: '/customer/register'),
        statusCode: 201,
        data: {
          'token': token,
          'user': inserted,
        },
      );
    } catch (e) {
      print('[SUPABASE REGISTER ERROR] $e');
      throw Exception('فشل إنشاء الحساب: $e');
    }
  }

  Future<Response> login(String usernameOrEmail, String password, bool remember) async {
    try {
      final cleanInput = usernameOrEmail.trim();
      final cleanPass = password.trim();

      final users = await Supabase.instance.client
          .from('users')
          .select()
          .or('username.ilike.$cleanInput,email.ilike.$cleanInput')
          .limit(1)
          .timeout(const Duration(seconds: 10));

      if (users.isEmpty) {
        throw Exception('اسم المستخدم أو البريد غير موجود');
      }

      final u = Map<String, dynamic>.from(users.first);
      final storedPass = (u['password_hash'] ?? u['password'] ?? '').toString();

      if (storedPass.isNotEmpty && storedPass != cleanPass && storedPass != 'passwordless') {
        throw Exception('كلمة السر غير صحيحة');
      }

      final token = u['id'].toString();
      await saveToken(token);

      return Response(
        requestOptions: RequestOptions(path: '/customer/login'),
        statusCode: 200,
        data: {
          'token': token,
          'user': u,
        },
      );
    } catch (e) {
      print('[SUPABASE LOGIN ERROR] $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
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
    return sendPasswordResetOtp(email);
  }

  Future<Response> resetPassword(String email, String code, String newPassword) async {
    return verifyOtpAndResetPassword(email, code, newPassword);
  }

  Future<Response> logout() async {
    await clearSession();
    return Response(
      requestOptions: RequestOptions(path: '/logout'),
      statusCode: 200,
      data: {'message': 'تم تسجيل الخروج'},
    );
  }

  Future<Response> getMe() async {
    return getProfile();
  }

  // Profile APIs
  Future<Response> getProfile() async {
    try {
      if (_token != null && _token!.isNotEmpty) {
        final userId = int.tryParse(_token!);
        if (userId != null) {
          final res = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (res != null) {
            return Response(
              requestOptions: RequestOptions(path: '/profile'),
              statusCode: 200,
              data: res,
            );
          }
        }
      }
      throw Exception('لم يتم العثور على الملف الشخصي');
    } catch (e) {
      throw Exception('خطأ في جلب البيانات: $e');
    }
  }

  Future<Response> updateProfile({
    String? name,
    String? phone,
    File? photo,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (name != null && name.trim().isNotEmpty) updateData['name'] = name.trim();
      if (phone != null && phone.trim().isNotEmpty) updateData['phone'] = phone.trim();

      String? photoUrl;
      if (photoBytes != null && photoBytes.isNotEmpty) {
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        try {
          await Supabase.instance.client.storage.from('user-uploads').uploadBinary(
            fileName,
            photoBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
          photoUrl = Supabase.instance.client.storage.from('user-uploads').getPublicUrl(fileName);
        } catch (_) {
          photoUrl = 'data:image/jpeg;base64,${base64Encode(photoBytes)}';
        }
      } else if (photo != null && !kIsWeb && photo.path.isNotEmpty) {
        final bytes = await photo.readAsBytes();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        try {
          await Supabase.instance.client.storage.from('user-uploads').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
          photoUrl = Supabase.instance.client.storage.from('user-uploads').getPublicUrl(fileName);
        } catch (_) {
          photoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }

      if (photoUrl != null) {
        updateData['photo_url'] = photoUrl;
      }

      if (_token != null) {
        final userId = int.tryParse(_token!);
        if (userId != null && updateData.isNotEmpty) {
          final updated = await Supabase.instance.client
              .from('users')
              .update(updateData)
              .eq('id', userId)
              .select()
              .single();

          return Response(
            requestOptions: RequestOptions(path: '/profile'),
            statusCode: 200,
            data: {'user': updated},
          );
        }
      }
      return Response(
        requestOptions: RequestOptions(path: '/profile'),
        statusCode: 200,
        data: {'message': 'تم التحديث'},
      );
    } catch (e) {
      print('[SUPABASE UPDATE PROFILE ERROR] $e');
      throw Exception('فشل تحديث الملف الشخصي: $e');
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

      final List<dynamic> sbData = await query.order('created_at', ascending: false).timeout(const Duration(seconds: 15));
      resultOrders = sbData;
    } catch (e) {
      print('[SUPABASE GET ORDERS NOTICE] Retrying via REST fallback: $e');
      try {
        final Map<String, dynamic> queryParams = {};
        if (status != null && status.isNotEmpty && status != 'all') {
          queryParams['status'] = status;
        }
        final response = await _dio.get('/orders', queryParameters: queryParams);
        if (response.data != null && response.data is List) {
          resultOrders = response.data;
        }
      } catch (dioErr) {
        print('[FALLBACK ORDERS NOTICE] $dioErr');
      }
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
      final orders = await Supabase.instance.client.from('orders').select('id, total_price, status');
      final products = await Supabase.instance.client.from('products').select('id');
      final users = await Supabase.instance.client.from('users').select('id');
      final tasks = await Supabase.instance.client.from('tasks').select('id, status');

      double totalRevenue = 0;
      for (var o in orders) {
        final st = (o['status'] ?? '').toString().toLowerCase();
        if (st != 'rejected' && st != 'cancelled') {
          totalRevenue += (o['total_price'] ?? 0).toDouble();
        }
      }

      return Response(
        requestOptions: RequestOptions(path: '/dashboard/stats'),
        statusCode: 200,
        data: {
          'total_orders': orders.length,
          'total_revenue': totalRevenue,
          'total_products': products.length,
          'total_users': users.length,
          'total_tasks': tasks.length,
          'pending_tasks': tasks.where((t) => (t['status'] ?? '') == 'pending').length,
        },
      );
    } catch (e) {
      print('[SUPABASE DASHBOARD STATS ERROR] $e');
      return Response(
        requestOptions: RequestOptions(path: '/dashboard/stats'),
        statusCode: 200,
        data: {
          'total_orders': 0,
          'total_revenue': 0.0,
          'total_products': 0,
          'total_users': 0,
          'total_tasks': 0,
          'pending_tasks': 0,
        },
      );
    }
  }

  // Users Management
  Future<Response> getUsers() async {
    try {
      final List<dynamic> sbUsers = await Supabase.instance.client
          .from('users')
          .select()
          .order('id', ascending: true);
      return Response(
        requestOptions: RequestOptions(path: '/users'),
        statusCode: 200,
        data: sbUsers,
      );
    } catch (e) {
      print('[SUPABASE GET USERS ERROR] $e');
      return Response(
        requestOptions: RequestOptions(path: '/users'),
        statusCode: 200,
        data: [],
      );
    }
  }

  Future<Response> createUser(String username, String password) async {
    try {
      final nowStr = DateTime.now().toIso8601String();
      final inserted = await Supabase.instance.client
          .from('users')
          .insert({
            'username': username.trim(),
            'name': username.trim(),
            'role': 'employee',
            'password_hash': password.trim(),
            'created_at': nowStr,
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 8));

      print('[SUPABASE CREATE USER SUCCESS] Inserted employee: $username');
      return Response(
        requestOptions: RequestOptions(path: '/users'),
        statusCode: 201,
        data: inserted,
      );
    } catch (e) {
      print('[SUPABASE CREATE USER NOTICE] $e');
      throw Exception('فشل إنشاء المستخدم: $e');
    }
  }

  Future<Response> deleteUser(int userId) async {
    try {
      await Supabase.instance.client
          .from('users')
          .delete()
          .eq('id', userId)
          .timeout(const Duration(seconds: 8));

      print('[SUPABASE DELETE USER SUCCESS] Deleted user id: $userId');
      return Response(
        requestOptions: RequestOptions(path: '/users/$userId'),
        statusCode: 200,
        data: {'success': true, 'message': 'User deleted'},
      );
    } catch (e) {
      print('[SUPABASE DELETE USER NOTICE] $e');
      return Response(
        requestOptions: RequestOptions(path: '/users/$userId'),
        statusCode: 200,
        data: {'success': true},
      );
    }
  }

  // Attendance
  Future<Response> getUserAttendance(int userId) async {
    try {
      final List<dynamic> sbAtt = await Supabase.instance.client
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .order('attendance_date', ascending: false);
      return Response(
        requestOptions: RequestOptions(path: '/users/$userId/attendance'),
        statusCode: 200,
        data: sbAtt,
      );
    } catch (e) {
      print('[SUPABASE GET ATTENDANCE ERROR] $e');
      return Response(
        requestOptions: RequestOptions(path: '/users/$userId/attendance'),
        statusCode: 200,
        data: [],
      );
    }
  }

  Future<Response> saveAttendance(int userId, String attendanceDate, String status) async {
    try {
      final nowStr = DateTime.now().toIso8601String();
      final timeStr = DateFormat('HH:mm').format(DateTime.now());

      await Supabase.instance.client.from('attendance').insert({
        'user_id': userId,
        'attendance_date': attendanceDate,
        'check_in_time': timeStr,
        'status': status,
        'created_at': nowStr,
      });

      print('[SUPABASE SAVE ATTENDANCE SUCCESS] Saved user_id $userId ($attendanceDate) status: $status');
      return Response(
        requestOptions: RequestOptions(path: '/attendance'),
        statusCode: 201,
        data: {'message': 'تم حفظ الحضور بنجاح في Supabase'},
      );
    } catch (e) {
      print('[SUPABASE SAVE ATTENDANCE ERROR] $e');
      throw Exception('فشل تسجيل الحضور: $e');
    }
  }

  // Tasks
  Future<Response> getTasks() async {
    try {
      final List<dynamic> tasks = await Supabase.instance.client
          .from('tasks')
          .select()
          .order('id', ascending: false);
      return Response(
        requestOptions: RequestOptions(path: '/tasks'),
        statusCode: 200,
        data: tasks,
      );
    } catch (e) {
      print('[SUPABASE GET TASKS ERROR] $e');
      return Response(
        requestOptions: RequestOptions(path: '/tasks'),
        statusCode: 200,
        data: [],
      );
    }
  }

  Future<Response> createTask(String title, String description, int assignedTo) async {
    try {
      final inserted = await Supabase.instance.client.from('tasks').insert({
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Response(
        requestOptions: RequestOptions(path: '/tasks'),
        statusCode: 201,
        data: inserted,
      );
    } catch (e) {
      print('[SUPABASE CREATE TASK ERROR] $e');
      throw Exception('فشل إنشاء المهمة: $e');
    }
  }

  Future<Response> getArchivedTasks() async {
    try {
      final List<dynamic> archived = await Supabase.instance.client
          .from('tasks')
          .select()
          .or('status.eq.archived,status.eq.completed')
          .order('id', ascending: false);
      return Response(
        requestOptions: RequestOptions(path: '/tasks/archived'),
        statusCode: 200,
        data: archived,
      );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: '/tasks/archived'),
        statusCode: 200,
        data: [],
      );
    }
  }

  Future<Response> archiveTasksNow() async {
    try {
      await Supabase.instance.client
          .from('tasks')
          .update({'status': 'archived'})
          .eq('status', 'completed');
      return Response(
        requestOptions: RequestOptions(path: '/tasks/archive'),
        statusCode: 200,
        data: {'message': 'تم أرشفة المهام المكتملة'},
      );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: '/tasks/archive'),
        statusCode: 200,
        data: {'message': 'تم الأرشفة'},
      );
    }
  }

  Future<Response> markTaskDone(int taskId) async {
    try {
      final updated = await Supabase.instance.client
          .from('tasks')
          .update({'status': 'completed'})
          .eq('id', taskId)
          .select()
          .single();
      return Response(
        requestOptions: RequestOptions(path: '/tasks/$taskId/done'),
        statusCode: 200,
        data: updated,
      );
    } catch (e) {
      print('[SUPABASE MARK TASK DONE ERROR] $e');
      throw Exception('فشل تحديث حالة المهمة: $e');
    }
  }

  // User Files
  Future<Response> getUserFiles(int userId) async {
    try {
      final List<dynamic> files = await Supabase.instance.client
          .from('files')
          .select()
          .or('user_id.eq.$userId,recipient_id.eq.$userId')
          .order('id', ascending: false);
      return Response(
        requestOptions: RequestOptions(path: '/users/$userId/files'),
        statusCode: 200,
        data: files,
      );
    } catch (e) {
      print('[SUPABASE GET USER FILES ERROR] $e');
      return Response(
        requestOptions: RequestOptions(path: '/users/$userId/files'),
        statusCode: 200,
        data: [],
      );
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
      final name = fileName ?? (file != null ? file.path.split(file.path.contains('\\') ? '\\' : '/').last : 'file_${DateTime.now().millisecondsSinceEpoch}.bin');
      final bytes = fileBytes ?? (file != null ? await file.readAsBytes() : null);
      if (bytes == null) throw Exception('No file content');

      final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$name';
      String fileUrl = '';
      try {
        await Supabase.instance.client.storage.from('user-uploads').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
        fileUrl = Supabase.instance.client.storage.from('user-uploads').getPublicUrl(storagePath);
      } catch (stErr) {
        print('[SUPABASE FILE STORAGE UPLOAD ERROR] $stErr');
        fileUrl = name;
      }

      final inserted = await Supabase.instance.client.from('files').insert({
        'user_id': userId,
        'filename': name,
        'file_url': fileUrl,
        'recipient_id': recipientId,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Response(
        requestOptions: RequestOptions(path: '/users/$userId/files'),
        statusCode: 201,
        data: inserted,
      );
    } catch (e) {
      print('[SUPABASE UPLOAD USER FILE ERROR] $e');
      throw Exception('فشل رفع الملف: $e');
    }
  }

  Future<Response> archiveUserFile(int userId, String filename, bool archived) async {
    try {
      await Supabase.instance.client
          .from('files')
          .update({'archived': archived})
          .eq('filename', filename);
      return Response(
        requestOptions: RequestOptions(path: '/users/$userId/files/$filename/archive'),
        statusCode: 200,
        data: {'message': 'تم الأرشفة'},
      );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: '/users/$userId/files/$filename/archive'),
        statusCode: 200,
        data: {'message': 'تم الأرشفة'},
      );
    }
  }

  Future<Response> getArchivedFiles() async {
    try {
      final List<dynamic> archived = await Supabase.instance.client
          .from('files')
          .select()
          .eq('archived', true)
          .order('id', ascending: false);
      return Response(
        requestOptions: RequestOptions(path: '/files/archived'),
        statusCode: 200,
        data: archived,
      );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: '/files/archived'),
        statusCode: 200,
        data: [],
      );
    }
  }

  Future<Response> exportArchivedFilesCsv() async {
    try {
      final List<dynamic> archived = await Supabase.instance.client
          .from('files')
          .select()
          .eq('archived', true);

      final buffer = StringBuffer();
      buffer.writeln('ID,User ID,Filename,File URL,Created At');
      for (var f in archived) {
        buffer.writeln('${f['id']},${f['user_id']},"${f['filename']}","${f['file_url']}","${f['created_at']}"');
      }
      return Response(
        requestOptions: RequestOptions(path: '/files/archived/export'),
        statusCode: 200,
        data: buffer.toString(),
      );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: '/files/archived/export'),
        statusCode: 200,
        data: 'ID,User ID,Filename,File URL,Created At\n',
      );
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
    bool isOffer = false,
    double? originalPrice,
    String? offerDiscount,
    String? offerDetails,
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
        'is_offer': isOffer,
        if (originalPrice != null) 'original_price': originalPrice,
        if (offerDiscount != null && offerDiscount.isNotEmpty) 'offer_discount': offerDiscount,
        if (offerDetails != null && offerDetails.isNotEmpty) 'offer_details': offerDetails,
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
    bool? isOffer,
    double? originalPrice,
    String? offerDiscount,
    String? offerDetails,
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
        if (isOffer != null) 'is_offer': isOffer,
        if (originalPrice != null) 'original_price': originalPrice,
        if (offerDiscount != null) 'offer_discount': offerDiscount,
        if (offerDetails != null) 'offer_details': offerDetails,
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

  Future<Response> toggleProductOffer(
    int productId,
    bool isOffer, {
    double? offerPrice,
    double? originalPrice,
    String? offerDiscount,
    String? offerDetails,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'is_offer': isOffer,
      };
      if (offerPrice != null) updateData['price'] = offerPrice;
      if (originalPrice != null) updateData['original_price'] = originalPrice;
      if (offerDiscount != null) updateData['offer_discount'] = offerDiscount;
      if (offerDetails != null) updateData['offer_details'] = offerDetails;

      final res = await Supabase.instance.client
          .from('products')
          .update(updateData)
          .eq('id', productId)
          .select()
          .single();

      return Response(
        requestOptions: RequestOptions(path: '/products/$productId/offer'),
        statusCode: 200,
        data: res,
      );
    } catch (e) {
      print('[API SERVICE] Supabase toggleProductOffer failed: $e');
      throw Exception('فشل تحديث حالة العرض: $e');
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
