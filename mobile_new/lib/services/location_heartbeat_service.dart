import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/supabase_service.dart';

// ========================================
// PHASE 5: LOCATION HEARTBEAT SERVICE 📍
// ========================================

/// Zomato-style location heartbeat for real-time tracking
/// Sends GPS updates every 10 seconds during active tasks
class LocationHeartbeatService {
  static final LocationHeartbeatService instance = LocationHeartbeatService._internal();
  LocationHeartbeatService._internal();

  Timer? _heartbeatTimer;
  String? _currentTaskId;
  String? _currentRiderId;

  /// Start heartbeat for an active task
  void startHeartbeat({
    required String taskId,
    required String riderId,
  }) {
    _currentTaskId = taskId;
    _currentRiderId = riderId;

    // Cancel existing timer if any
    _heartbeatTimer?.cancel();

    // Send heartbeat every 10 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _sendLocationUpdate();
    });

    // Send first update immediately
    _sendLocationUpdate();
  }

  /// Stop heartbeat when task is completed/cancelled
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _currentTaskId = null;
    _currentRiderId = null;
  }

  /// Send location update to database
  Future<void> _sendLocationUpdate() async {
    if (_currentTaskId == null || _currentRiderId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await SupabaseService.instance.client.from('location_updates').insert({
        'rider_id': _currentRiderId,
        'task_id': _currentTaskId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'bearing': position.heading,
      });

      print('📍 Heartbeat sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Heartbeat failed: $e');
      // Don't throw - heartbeat failures shouldn't crash the app
    }
  }

  /// Check if heartbeat is currently active
  bool get isActive => _heartbeatTimer != null && _heartbeatTimer!.isActive;
}
