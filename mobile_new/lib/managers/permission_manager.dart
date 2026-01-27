import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  static PermissionManager get instance => _instance;

  PermissionManager._internal();

  /// Requests permissions required for the "Online" worker mode.
  /// Returns true if all critical permissions are granted.
  Future<bool> requestWorkerPermissions(BuildContext context) async {
    // 1. Location (Foreground)
    var locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
       locationStatus = await Permission.locationWhenInUse.request();
       if (!locationStatus.isGranted) {
         _showSettingsDialog(context, 'Location permission is needed to find nearby gigs.');
         return false;
       }
    }

    // 2. Location (Background - Optional but recommended for better experience)
    // Note: Android 11+ requires separate request for background.
    // For MVP/Demo, foreground might be enough if app is open, but for "Real" premium reliability, we need background.
    // Simplifying to foreground strict for now to avoid complexity with Google Play policies in demo.
    
    // 3. Notifications
    var notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) {
        _showSettingsDialog(context, 'Notification permission is needed to alert you of new gigs.');
        return false;
      }
    }

    return true;
  }

  void _showSettingsDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}
