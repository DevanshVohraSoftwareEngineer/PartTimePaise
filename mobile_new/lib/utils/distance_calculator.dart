import 'dart:math';

class DistanceCalculator {
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
        cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Return distance in meters instead of kilometers
    return (earthRadiusKm * c) * 1000;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  /// Format distance for display
  static String formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m away';
    } else {
      final distanceKm = distanceMeters / 1000;
      if (distanceKm < 10) {
        return '${distanceKm.toStringAsFixed(1)} km away';
      } else {
        return '${distanceKm.round()} km away';
      }
    }
  }
}
