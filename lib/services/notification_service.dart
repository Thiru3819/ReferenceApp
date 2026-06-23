import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling notifications and permissions
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification service
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  /// Request all necessary permissions
  static Future<void> requestPermissions() async {
    // Request notification permission
    await _requestNotificationPermission();
    
    // Request other useful permissions
    await _requestOtherPermissions();
  }

  /// Request notification permission
  static Future<void> _requestNotificationPermission() async {
    // For Android 13+ (API 33+)
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Request other permissions that might be useful
  static Future<void> _requestOtherPermissions() async {
    // You can add more permissions here as needed
    // Example: location, camera, etc.
  }

  /// Show a simple notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'divine_queue_channel',
      'DivineQueue Notifications',
      channelDescription: 'Notifications for DivineQueue app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Show queue position update notification
  static Future<void> showQueueUpdateNotification({
    required int position,
    required int totalInQueue,
  }) async {
    await showNotification(
      id: 1,
      title: 'Queue Update',
      body: 'Your position: #$position of $totalInQueue people',
    );
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
