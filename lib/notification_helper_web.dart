import 'dart:html' as html;

class PlatformNotificationHelper {
  static Future<void> initialize() async {}

  static Future<bool> requestPermission() async {
    try {
      if (!html.Notification.supported) {
        return false;
      }
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (e) {
      return false;
    }
  }

  static Future<void> showNotification(String title, String body) async {
    try {
      if (!html.Notification.supported) {
        return;
      }
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body);
      }
    } catch (e) {
      // Ignore
    }
  }
}
