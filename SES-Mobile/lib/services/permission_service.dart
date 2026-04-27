import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests the necessary permissions for the silent emergency shield.
  /// Returns true if all critical permissions are granted.
  static Future<bool> requestEmergencyPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.microphone,
      Permission.notification,
      Permission.sms,
    ].request();

    bool isLocationGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? false;
    bool isMicGranted = statuses[Permission.microphone]?.isGranted ?? false;

    // We can also try requesting background location separately as required by Android/iOS
    if (isLocationGranted) {
      PermissionStatus bgStatus = await Permission.locationAlways.request();
      if (!bgStatus.isGranted) {
        // Just log or handle if we really need "Always" location, but "When In Use" is minimally required.
      }
    }

    // Attempt to exempt the app from Battery Optimizations to keep background listener alive
    PermissionStatus batteryStatus = await Permission.ignoreBatteryOptimizations.request();
    if (!batteryStatus.isGranted) {
      // Log warning, battery optimizations might kill the background service.
    }

    return isLocationGranted && isMicGranted;
  }

  /// Check if we have the required permissions
  static Future<bool> hasRequiredPermissions() async {
    bool hasLoc = await Permission.locationWhenInUse.isGranted || await Permission.locationAlways.isGranted;
    bool hasMic = await Permission.microphone.isGranted;
    return hasLoc && hasMic;
  }
}
