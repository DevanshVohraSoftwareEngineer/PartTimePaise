import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/supabase_service.dart';
import '../data_types/user.dart';
import '../managers/auth_provider.dart';

// 1. Separate Provider to hold the CURRENT logical location (debounced/bucketed)
final stabilizedLocationProvider = StateProvider<Position?>((ref) => null);

class NearbyUsersNotifier extends StateNotifier<List<User>> {
  final SupabaseService _supabaseService;
  final Ref _ref;
  StreamSubscription? _subscription;

  NearbyUsersNotifier(this._supabaseService, this._ref) : super([]) {
    // Listen to location changes and RE-INIT filter logic if needed
    _ref.listen<Position?>(stabilizedLocationProvider, (prev, next) {
      _listenToOnlineUsers();
    });
    
    _listenToOnlineUsers();
  }

  void _listenToOnlineUsers() {
    final location = _ref.read(stabilizedLocationProvider);
    final currentUserId = _ref.read(authProvider).user?.id;

    _subscription?.cancel();
    
    if (location == null) {
      state = [];
      return;
    }

    _subscription = _supabaseService.getOnlineUsersStream().listen((usersData) {
      final List<User> nearby = [];
      
      for (var data in usersData) {
        if (data['id'] == currentUserId) continue;

        final lat = (data['current_lat'] as num?)?.toDouble() ?? (data['last_lat'] as num?)?.toDouble();
        final lng = (data['current_lng'] as num?)?.toDouble() ?? (data['last_lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          final distance = Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            lat,
            lng,
          );

          // Proximity Filter: 10km radius (Expanded for testing)
          if (distance <= 10000) {
            nearby.add(User(
              id: data['id'],
              name: data['name'] ?? 'User',
              email: data['email'] ?? '',
              avatarUrl: data['avatar_url'],
              role: data['role'] ?? 'worker',
              college: data['college'],
              verified: data['verified'] == true,
              isOnline: true,
              currentLat: lat,
              currentLng: lng,
              distanceMeters: distance,
              createdAt: DateTime.now(),
            ));
          }
        }
      }
      state = nearby;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ✨ Magic: Global single instance provider. NO MORE .family for positions!
final nearbyUsersProvider = StateNotifierProvider<NearbyUsersNotifier, List<User>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return NearbyUsersNotifier(supabase, ref);
});
