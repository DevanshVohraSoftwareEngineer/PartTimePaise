import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

import '../data_types/gig_request.dart';

final gigRequestsProvider = StateNotifierProvider<GigRequestsNotifier, List<GigRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  return GigRequestsNotifier(ref.read(supabaseServiceProvider), user?.id);
});

class GigRequestsNotifier extends StateNotifier<List<GigRequest>> {
  final SupabaseService _supabaseService;
  final String? _userId;
  StreamSubscription? _subscription;

  GigRequestsNotifier(this._supabaseService, this._userId) : super([]) {
    if (_userId != null) {
      _init();
    }
  }

  void _init() {
    print('🚨 GigRequestsNotifier: Initializing stream for user $_userId');
    _subscription = _supabaseService.getPendingGigRequestsStream().listen((data) {
      print('🚨 GigRequestsNotifier: Received ${data.length} requests from DB');
      state = data
          .map((e) => GigRequest.fromJson(e))
          .where((r) => !r.isExpired)
          .toList();
    });
  }

  Future<void> updateStatus(String requestId, String status) async {
    await _supabaseService.client
        .from('gig_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
