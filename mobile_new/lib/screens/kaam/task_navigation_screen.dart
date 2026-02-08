import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/map_service.dart';

class TaskNavigationScreen extends StatefulWidget {
  final LatLng taskLocation;
  final String taskTitle;

  const TaskNavigationScreen({
    super.key,
    required this.taskLocation,
    required this.taskTitle,
  });

  @override
  State<TaskNavigationScreen> createState() => _TaskNavigationScreenState();
}

class _TaskNavigationScreenState extends State<TaskNavigationScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  List<LatLng> _polylinePoints = [];
  String _distance = '-- km';
  String _duration = '-- min';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initNavigation();
  }

  Future<void> _initNavigation() async {
    try {
      // 1. Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // 2. Fetch Route
      final routeData = await MapService.getRouteData(
        _currentPosition!,
        widget.taskLocation,
      );

      if (!mounted) return;
      setState(() {
        _polylinePoints = routeData['polylinePoints'];
        _distance = routeData['distance'];
        _duration = routeData['duration'];
        _isLoading = false;
      });

      // 3. Adjust camera to see both points
      _fitRoute();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.nopeRed),
        );
      }
    }
  }

  void _fitRoute() {
    if (_mapController == null || _currentPosition == null) return;

    LatLngBounds bounds;
    if (_currentPosition!.latitude > widget.taskLocation.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(widget.taskLocation.latitude, 
                         _currentPosition!.longitude < widget.taskLocation.longitude 
                             ? _currentPosition!.longitude : widget.taskLocation.longitude),
        northeast: LatLng(_currentPosition!.latitude,
                         _currentPosition!.longitude > widget.taskLocation.longitude 
                             ? _currentPosition!.longitude : widget.taskLocation.longitude),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(_currentPosition!.latitude,
                         _currentPosition!.longitude < widget.taskLocation.longitude 
                             ? _currentPosition!.longitude : widget.taskLocation.longitude),
        northeast: LatLng(widget.taskLocation.latitude,
                         _currentPosition!.longitude > widget.taskLocation.longitude 
                             ? _currentPosition!.longitude : widget.taskLocation.longitude),
      );
    }
    
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  Future<void> _startExternalNavigation() async {
    final url = MapService.getGoogleMapsUrl(
      widget.taskLocation.latitude,
      widget.taskLocation.longitude,
    );
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback to web URL
      final webUrl = 'https://www.google.com/maps/search/?api=1&query=${widget.taskLocation.latitude},${widget.taskLocation.longitude}';
      await launchUrl(Uri.parse(webUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskTitle, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.taskLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              if (_currentPosition != null)
                Marker(
                  markerId: const MarkerId('current'),
                  position: _currentPosition!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              Marker(
                markerId: const MarkerId('task'),
                position: widget.taskLocation,
                infoWindow: InfoWindow(title: widget.taskTitle),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: _polylinePoints,
                color: AppTheme.navyMedium,
                width: 5,
              ),
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Bottom Control Panel
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoItem(Icons.directions_walk, _distance, "Distance"),
                      _infoItem(Icons.timer, _duration, "ETA"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startExternalNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyDark,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Start Navigation', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.navyMedium, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w900, color: AppTheme.navyDark)),
            Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600)),
          ],
        ),
      ],
    );
  }
}
