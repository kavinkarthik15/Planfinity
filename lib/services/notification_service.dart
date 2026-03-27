import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'planfinity_alerts',
    'Planfinity Alerts',
    description: 'Important spending and budget alerts',
    importance: Importance.max,
  );
  
  // Global key for navigating to specific screens
  static GlobalKey<NavigatorState>? navigatorKey;
  
  Future<void> init() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageTap(message);
    });
  }

  Future<String?> getToken() async {
    return _firebaseMessaging.getToken();
  }

  static Future<void> initialize(GlobalKey<NavigatorState> key) async {
    navigatorKey = key;
    await NotificationService().init();
  }
  
  static void _handleForegroundMessage(RemoteMessage message) {
    // Show a system notification even when app is foregrounded.
    if (message.notification != null) {
      debugPrint('Notification: ${message.notification?.title}');

      _localNotifications.show(
        message.hashCode,
        message.notification!.title ?? 'Planfinity Alert',
        message.notification!.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );

      ScaffoldMessenger.of(navigatorKey!.currentContext!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification!.title ?? 'Alert',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(message.notification!.body ?? ''),
            ],
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
  }
  
  static void _handleMessageTap(RemoteMessage message) {
    // Navigate based on notification type
    if (message.data['alertType'] == 'budget') {
      navigatorKey?.currentState?.pushNamed('/budget');
    } else if (message.data['alertType'] == 'spending') {
      navigatorKey?.currentState?.pushNamed('/dashboard');
    }
  }
  
  // Test notification
  static Future<void> sendTestNotification(String title, String body) async {
    // This would be called from backend in production
  }
}
