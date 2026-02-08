import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapService {
  static const String _googleApiKey = "YOUR_GOOGLE_MAPS_API_KEY_HERE"; // Placeholder

  /// Fetches a route between origin and destination using Google Directions API
  static Future<Map<String, dynamic>> getRouteData(LatLng origin, LatLng destination) async {
    final String url = 
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];
          final points = PolylinePoints().decodePolyline(route['overview_polyline']['points']);
          
          return {
            'distance': distance,
            'duration': duration,
            'polylinePoints': points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          };
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to fetch directions');
      }
    } catch (e) {
      print('❌ MapService Error: $e');
      rethrow;
    }
  }

  /// Launch external Google Maps navigation
  static String getGoogleMapsUrl(double lat, double lng) {
    return 'google.navigation:q=$lat,$lng&mode=d';
  }
}
