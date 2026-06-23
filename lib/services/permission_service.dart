import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions
class PermissionService {
  /// Request all necessary permissions for the app
  static Future<void> requestPermissions() async {
    // Request notification permission (required for Android 13+)
    await _requestNotificationPermission();
    
    // You can add more permissions here as needed
    // await _requestLocationPermission();
    // await _requestCameraPermission();
  }

  /// Request notification permission
  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Check notification permission status
  static Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open app settings if permissions are denied
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Request location permission (optional - uncomment if needed)
  static Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  /// Request camera permission (optional - uncomment if needed)
  static Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }
}
