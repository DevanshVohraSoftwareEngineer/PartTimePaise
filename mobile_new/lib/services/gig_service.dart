import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../managers/auth_provider.dart';
import '../managers/location_provider.dart';
import '../managers/permission_manager.dart';
import '../services/supabase_service.dart';
import '../data_types/gig_request.dart';

final gigServiceProvider = Provider<GigService>((ref) {
  return GigService(ref);
});

final isOnlineProvider = StateProvider<bool>((ref) => false);
final gigRequestsStreamProvider = StreamProvider<List<GigRequest>>((ref) {
  final gigService = ref.watch(gigServiceProvider);
  return gigService.getGigRequestsStream();
});

class GigService {
  final Ref _ref;
  Timer? _heartbeatTimer;
  StreamSubscription<Position>? _locationSubscription;
  final _supabase = Supabase.instance.client;

  GigService(this._ref);

  Future<void> goOnline(BuildContext context) async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    // 0. Check Permissions
    final hasPermissions = await PermissionManager.instance.requestWorkerPermissions(context);
    if (!hasPermissions) return;

    // 1. Request permissions and start tracking
    final locationMgr = _ref.read(locationTrackingManagerProvider);
    await locationMgr.startLocationTracking();

    // 2. Update DB status
    await _supabase.from('profiles').update({
      'is_online': true,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    _ref.read(isOnlineProvider.notifier).state = true;

    // 3. Listen to location updates
    final locationService = _ref.read(locationServiceProvider);
    _locationSubscription?.cancel();
    _locationSubscription = locationService.getPositionStream().listen((position) {
      _updateLiveLocation(position);
    });

    // 4. HEARTBEAT: Ensure we stay visible even if stationary
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      final pos = await Geolocator.getCurrentPosition();
      _updateLiveLocation(pos);
    });
  }

  Future<void> goOffline() async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    // 1. Stop tracking locally
    final locationMgr = _ref.read(locationTrackingManagerProvider);
    await locationMgr.stopLocationTracking();
    _locationSubscription?.cancel();
    _heartbeatTimer?.cancel();

    // 2. Update DB status
    await _supabase.from('profiles').update({
      'is_online': false,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    _ref.read(isOnlineProvider.notifier).state = false;
  }

  Future<void> _updateLiveLocation(Position position) async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    // Optimize: Only update if moved significantly or every X seconds? 
    // For now, update every change (High-priority tracking needs high precision)
    try {
      await _supabase.from('profiles').update({
        'current_lat': position.latitude,
        'current_lng': position.longitude,
        'lat': position.latitude, // Update legacy fields too just in case
        'lng': position.longitude,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      print('Error updating live location: $e');
    }
  }

  Stream<List<GigRequest>> getGigRequestsStream() {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('gig_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .where((json) => json['worker_id'] == userId && json['status'] == 'pending')
              .map((json) => GigRequest.fromJson(json))
              .toList();
        });
  }

  Future<void> acceptGig(String requestId) async {
     await _supabase.rpc('accept_gig', params: {'request_id': requestId});
  }

  Future<void> rejectGig(String requestId) async {
    await _supabase.from('gig_requests').update({
      'status': 'rejected',
    }).eq('id', requestId);
  }
}
