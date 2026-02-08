import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/theme.dart';
import '../services/map_service.dart';

/// A reusable widget that displays a route between two points on a Google Map
/// including distance and ETA labels.
class RoutePreviewWidget extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String destinationTitle;
  final double height;

  const RoutePreviewWidget({
    super.key,
    required this.origin,
    required this.destination,
    this.destinationTitle = 'Destination',
    this.height = 300,
  });

  @override
  State<RoutePreviewWidget> createState() => _RoutePreviewWidgetState();
}

class _RoutePreviewWidgetState extends State<RoutePreviewWidget> {
  GoogleMapController? _mapController;
  List<LatLng> _polylinePoints = [];
  String _distance = '--';
  String _duration = '--';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final data = await MapService.getRouteData(widget.origin, widget.destination);
      if (mounted) {
        setState(() {
          _polylinePoints = data['polylinePoints'];
          _distance = data['distance'];
          _duration = data['duration'];
          _isLoading = false;
        });
        _fitBounds();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fitBounds() {
    if (_mapController == null) return;
    
    final bounds = _calculateBounds(widget.origin, widget.destination);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _calculateBounds(LatLng p1, LatLng p2) {
    final southwest = LatLng(
      p1.latitude < p2.latitude ? p1.latitude : p2.latitude,
      p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
    );
    final northeast = LatLng(
      p1.latitude > p2.latitude ? p1.latitude : p2.latitude,
      p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
    );
    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.destination, zoom: 14),
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isLoading) _fitBounds();
            },
            markers: {
              Marker(
                markerId: const MarkerId('origin'),
                position: widget.origin,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: widget.destination,
                infoWindow: InfoWindow(title: widget.destinationTitle),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: _polylinePoints,
                color: AppTheme.navyMedium,
                width: 4,
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Mini Info Header
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppTheme.navyMedium),
                  const SizedBox(width: 4),
                  Text(
                    '$_duration ($_distance)',
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navyDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
