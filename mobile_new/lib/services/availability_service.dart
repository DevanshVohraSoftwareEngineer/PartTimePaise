import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

class AvailabilityService extends StateNotifier<bool> {
  final SupabaseService _supabaseService;
  Timer? _heartbeatTimer;

  AvailabilityService(this._supabaseService) : super(false) {
    _init();
  }

  Future<void> _init() async {
    final user = _supabaseService.currentUser;
    if (user != null) {
      // Fetch initial status from profiles
      final response = await _supabaseService.client
          .from('profiles')
          .select('is_online')
          .eq('id', user.id)
          .single();
      state = response['is_online'] ?? false;
      if (state) _startHeartbeat();
    }
  }

  Future<void> toggleAvailability() async {
    final newStatus = !state;
    try {
      await _supabaseService.setAvailability(newStatus);
      state = newStatus;
      if (state) {
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
    } catch (e) {
      print('❌ Toggle failed: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _supabaseService.sendHeartbeat();
    });
    // First heartbeat immediate
    _supabaseService.sendHeartbeat();
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void dispose() {
    _stopHeartbeat();
    super.dispose();
  }
}

final availabilityProvider = StateNotifierProvider<AvailabilityService, bool>((ref) {
  return AvailabilityService(ref.watch(supabaseServiceProvider));
});
