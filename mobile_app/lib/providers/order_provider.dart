import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OrderModel> _orders = [];
  final Set<String> _myOrderIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;

  List<OrderModel> get orders => _orders;
  Set<String> get myOrderIds => _myOrderIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearOrders() {
    _orders = [];
    _myOrderIds.clear();
    _realtimeSubscription?.cancel();
    notifyListeners();
  }

  void registerCreatedOrderId(dynamic id) {
    if (id != null) {
      _myOrderIds.add(id.toString());
      notifyListeners();
    }
  }

  void addLocalOrder(OrderModel order) {
    _myOrderIds.add(order.id.toString());
    final existingIdx = _orders.indexWhere((o) => o.id == order.id);
    if (existingIdx >= 0) {
      _orders[existingIdx] = order;
    } else {
      _orders.insert(0, order);
    }
    _orders.sort((a, b) => b.id.compareTo(a.id));
    notifyListeners();
  }

  Future<void> fetchOrders({String status = 'all', UserModel? currentUser}) async {
    if (_orders.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    if (currentUser == null) {
      _orders = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Initialize Supabase Realtime Stream for instant status updates if not subscribed
    _initRealtimeStream(currentUser);

    try {
      final response = await _apiService.getOrders(
        status: status,
        userId: currentUser.id,
        userPhone: currentUser.phone,
        userName: currentUser.displayName ?? currentUser.name ?? currentUser.username,
        isStaff: currentUser.isAdmin || currentUser.isEmployee,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final fetchedOrders = data.map((json) => OrderModel.fromJson(json)).toList();

        final isStaff = currentUser.isAdmin || currentUser.isEmployee;
        if (!isStaff) {
          final uIdStr = (currentUser.id ?? 0).toString();
          final uPhoneStr = (currentUser.phone ?? '').trim().replaceAll(RegExp(r'\D'), '');
          final uNameStr = (currentUser.displayName ?? currentUser.name ?? currentUser.username ?? '').trim().toLowerCase();

          _orders = fetchedOrders.where((o) {
            final oIdStr = o.id.toString();
            final oUserId = o.userId.toString();
            final oPhone = o.customerPhone.trim().replaceAll(RegExp(r'\D'), '');
            final oName = o.customerName.trim().toLowerCase();

            // 1. Created locally in this session
            if (_myOrderIds.contains(oIdStr)) return true;

            // 2. User ID match
            if (uIdStr != '0' && uIdStr.isNotEmpty && oUserId != '0' && oUserId.isNotEmpty && oUserId == uIdStr) {
              return true;
            }

            // 3. Phone match
            if (uPhoneStr.length >= 8 && oPhone.length >= 8 && (oPhone == uPhoneStr || oPhone.endsWith(uPhoneStr) || uPhoneStr.endsWith(oPhone))) {
              return true;
            }

            // 4. Name match
            if (uNameStr.length >= 3 && oName.length >= 3 && (oName == uNameStr || oName.contains(uNameStr) || uNameStr.contains(oName))) {
              return true;
            }

            return false;
          }).toList();
        } else {
          _orders = fetchedOrders;
        }

        // ALWAYS SORT FROM NEWEST TO OLDEST (الأحدث للأقدم)
        _orders.sort((a, b) => b.id.compareTo(a.id));
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _initRealtimeStream(UserModel currentUser) {
    if (_realtimeSubscription != null) return;

    try {
      _realtimeSubscription = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .listen((data) {
        if (data.isNotEmpty) {
          try {
            SystemSound.play(SystemSoundType.alert);
            HapticFeedback.vibrate();
          } catch (_) {}
          fetchOrders(currentUser: currentUser);
        }
      }, onError: (err) {
        print('[ORDERS REALTIME STREAM NOTICE] $err');
      });
    } catch (e) {
      print('[ORDERS REALTIME SETUP NOTICE] $e');
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status, {String? reason}) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    OrderModel? oldOrder;
    if (index != -1) {
      oldOrder = _orders[index];
      _orders[index] = OrderModel(
        id: oldOrder.id,
        userId: oldOrder.userId,
        customerName: oldOrder.customerName,
        customerPhone: oldOrder.customerPhone,
        productIds: oldOrder.productIds,
        itemsSummary: oldOrder.itemsSummary,
        products: oldOrder.products,
        status: status,
        totalPrice: oldOrder.totalPrice,
        paymentMethod: oldOrder.paymentMethod,
        paymentProofUrl: oldOrder.paymentProofUrl,
        rejectionReason: reason ?? oldOrder.rejectionReason,
        createdAt: oldOrder.createdAt,
      );
      _orders.sort((a, b) => b.id.compareTo(a.id));
      notifyListeners();
    }

    try {
      final targetUserId = oldOrder?.userId;
      final response = await _apiService.updateOrderStatus(
        orderId,
        status,
        reason: reason,
        userId: targetUserId,
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      if (index != -1 && oldOrder != null) {
        _orders[index] = oldOrder;
        _orders.sort((a, b) => b.id.compareTo(a.id));
        notifyListeners();
      }
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
