import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    fetchNotifications();
  }

  /// Fetches notifications from Supabase DB for current user or broadcast
  Future<void> fetchNotifications({UserModel? currentUser, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      var query = Supabase.instance.client.from('notifications').select();

      final isStaff = currentUser != null && (currentUser.isAdmin || currentUser.isEmployee);
      if (!isStaff && currentUser != null && currentUser.id > 0) {
        query = query.or('user_id.eq.${currentUser.id},user_id.eq.0,user_id.is.null');
      }

      final List<dynamic> data = await query
          .order('created_at', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 8));

      final fetchedList = data.map((json) => NotificationModel.fromJson(json)).toList();
      _notifications = fetchedList;

      // Subscribe to Supabase Real-time stream if not already active
      _initRealtimeSubscription(currentUser);
    } catch (e) {
      print('[SUPABASE NOTIFICATIONS FETCH NOTICE] $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Subscribes to Supabase Realtime stream for live pop-up notifications
  void _initRealtimeSubscription(UserModel? currentUser) {
    if (_realtimeSubscription != null) return;

    try {
      _realtimeSubscription = Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .listen((data) {
        if (data.isNotEmpty) {
          final latestJson = data.last;
          final latestNotif = NotificationModel.fromJson(latestJson);

          // Check if notification belongs to user or is broadcast (user_id = 0)
          final isStaff = currentUser != null && (currentUser.isAdmin || currentUser.isEmployee);
          final isForMe = isStaff || currentUser == null || latestNotif.userId == 0 || latestNotif.userId == currentUser.id;

          if (isForMe) {
            final exists = _notifications.any((n) => n.id == latestNotif.id);
            if (!exists) {
              _notifications.insert(0, latestNotif);
              notifyListeners();

              // Trigger real System Bar Notification pop-up with sound & vibration!
              _notificationService.showNotification(
                id: latestNotif.id,
                title: latestNotif.title,
                body: latestNotif.message,
              );
            }
          }
        }
      }, onError: (err) {
        print('[SUPABASE NOTIFICATIONS REALTIME NOTICE] $err');
      });
    } catch (e) {
      print('[SUPABASE NOTIFICATIONS REALTIME SETUP NOTICE] $e');
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) {
      return NotificationModel(
        id: n.id,
        userId: n.userId,
        title: n.title,
        message: n.message,
        isRead: true,
        createdAt: n.createdAt,
      );
    }).toList();
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (_) {}
  }

  void addOrderNotification({required String title, required String message, int userId = 0}) async {
    final notifId = DateTime.now().millisecondsSinceEpoch % 100000;
    final orderNotification = NotificationModel(
      id: notifId,
      userId: userId,
      title: title,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, orderNotification);
    notifyListeners();

    // Show System Bar Notification
    _notificationService.showNotification(
      id: notifId,
      title: title,
      body: message,
    );

    // Save to Supabase DB
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[ADD NOTIFICATION DB NOTICE] $e');
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
