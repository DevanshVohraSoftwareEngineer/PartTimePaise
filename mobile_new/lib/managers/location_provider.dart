import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../helpers/location_service.dart';
import '../services/supabase_service.dart';

// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// Current location provider
final currentLocationProvider = StateNotifierProvider<LocationNotifier, AsyncValue<Position?>>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

// Location tracking state
final locationTrackingProvider = StateNotifierProvider<LocationTrackingNotifier, bool>((ref) {
  return LocationTrackingNotifier();
});

class LocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const AsyncValue.loading()) {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      state = AsyncValue.data(position);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshLocation() async {
    state = const AsyncValue.loading();
    try {
      final position = await _locationService.getCurrentLocation();
      state = AsyncValue.data(position);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void updateLocation(Position position) {
    state = AsyncValue.data(position);
  }
}

class LocationTrackingNotifier extends StateNotifier<bool> {
  LocationTrackingNotifier() : super(false);

  void startTracking() {
    state = true;
  }

  void stopTracking() {
    state = false;
  }

  void toggleTracking() {
    state = !state;
  }
}

// Location permissions provider
final locationPermissionProvider = StateNotifierProvider<LocationPermissionNotifier, LocationPermission>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationPermissionNotifier(locationService);
});

class LocationPermissionNotifier extends StateNotifier<LocationPermission> {
  final LocationService _locationService;

  LocationPermissionNotifier(this._locationService) : super(LocationPermission.denied) {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final permission = await Geolocator.checkPermission();
    state = permission;
  }

  Future<bool> requestPermission() async {
    final granted = await _locationService.requestLocationPermission();
    if (granted) {
      final permission = await Geolocator.checkPermission();
      state = permission;
    }
    return granted;
  }

  Future<void> openSettings() async {
    await _locationService.openLocationSettings();
  }
}

// Location tracking manager provider
final locationTrackingManagerProvider = Provider<LocationTrackingManager>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final locationNotifier = ref.watch(currentLocationProvider.notifier);
  final trackingNotifier = ref.watch(locationTrackingProvider.notifier);
  return LocationTrackingManager(locationService, locationNotifier, trackingNotifier);
});

class LocationTrackingManager {
  final LocationService _locationService;
  final LocationNotifier _locationNotifier;
  final LocationTrackingNotifier _trackingNotifier;
  StreamSubscription<Position>? _locationSubscription;

  LocationTrackingManager(this._locationService, this._locationNotifier, this._trackingNotifier);

  Future<void> startLocationTracking() async {
    // Check permissions first
    final hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission) return;

    // Check if location services are enabled
    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Start tracking
    _trackingNotifier.startTracking();

    // Cancel existing subscription
    await _locationSubscription?.cancel();

    // Start listening to location updates
    _locationSubscription = _locationService.getPositionStream().listen(
      (Position position) {
        _locationNotifier.updateLocation(position);
        
        // ✨ Magic: Sync location to Supabase for distance filtering
        SupabaseService.instance.updateLocation(position.latitude, position.longitude);
      },
      onError: (error) {
        print('Location tracking error: $error');
        stopLocationTracking();
      },
    );
  }

  Future<void> stopLocationTracking() async {
    _trackingNotifier.stopTracking();
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void dispose() {
    _locationSubscription?.cancel();
  }
}
