import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../widgets/notifications_modal.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initializes notification channel & permissions
  Future<void> init([BuildContext? context]) async {
    if (_isInitialized || kIsWeb) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: DarwinInitializationSettings(),
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (context != null && context.mounted) {
            openNotifications(context);
          }
        },
      );

      // Create Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'bola_designs_channel',
        'إشعارات بولا ديزاينز',
        description: 'قناة الإشعارات الفورية والعروض والطلبات من بولا ديزاينز',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
      print('[NOTIFICATION SERVICE] Successfully initialized Flutter Local Notifications.');
    } catch (e) {
      print('[NOTIFICATION SERVICE ERROR] $e');
    }
  }

  /// Displays a system bar notification on the phone with sound & vibration
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (kIsWeb) return;
    try {
      if (!_isInitialized) {
        await init();
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'bola_designs_channel',
        'إشعارات بولا ديزاينز',
        channelDescription: 'قناة الإشعارات الفورية والعروض والطلبات من بولا ديزاينز',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'إشعار جديد من بولا ديزاينز',
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
      );

      await _notificationsPlugin.show(
        id == 0 ? DateTime.now().millisecondsSinceEpoch % 100000 : id,
        title,
        body,
        platformDetails,
      );
    } catch (e) {
      print('[SHOW NOTIFICATION ERROR] $e');
    }
  }

  /// Opens notifications modal on notification click/tap
  static void openNotifications(BuildContext context) {
    NotificationsModal.show(context);
  }
}
