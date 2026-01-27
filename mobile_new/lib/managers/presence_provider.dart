import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final onlineCountProvider = StreamProvider<int>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.globalOnlineCountStream;
});

class PresenceNotifier extends StateNotifier<void> {
  final SupabaseService _supabase;

  PresenceNotifier(this._supabase) : super(null);

  Future<void> updateLocation(double lat, double lng) async {
    await _supabase.updateLocation(lat, lng);
  }
}

final presenceProvider = StateNotifierProvider<PresenceNotifier, void>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return PresenceNotifier(supabase);
});
