import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../../config/theme.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String partnerId;
  final String partnerRole; // 'client' or 'worker'
  final LatLng initialPosition;

  const LiveTrackingScreen({
    super.key,
    required this.taskId,
    required this.partnerId,
    required this.partnerRole,
    required this.initialPosition,
  });

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  StreamSubscription? _partnerLocationSub;
  LatLng? _partnerPos;

  @override
  void initState() {
    super.initState();
    _partnerPos = widget.initialPosition;
    _subscribeToPartnerLocation();
  }

  void _subscribeToPartnerLocation() {
    final supabase = ref.read(supabaseServiceProvider);
    
    // Listen to real-time updates for the partner's profile
    // Only coordinates are fetched due to RLS
    _partnerLocationSub = supabase.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.partnerId)
        .listen((data) {
          if (data.isNotEmpty) {
            final profile = data.first;
            final lat = profile['current_lat'] as double?;
            final lng = profile['current_lng'] as double?;
            
            if (lat != null && lng != null) {
              setState(() {
                _partnerPos = LatLng(lat, lng);
                _updateMarkers();
              });
            }
          }
        });
  }

  void _updateMarkers() {
    if (_partnerPos == null) return;

    final markerId = MarkerId(widget.partnerId);
    final marker = Marker(
      markerId: markerId,
      position: _partnerPos!,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        widget.partnerRole == 'worker' ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
      ),
      infoWindow: InfoWindow(
        title: widget.partnerRole == 'worker' ? 'Worker' : 'Client',
        snippet: 'Live Tracking Active',
      ),
    );

    setState(() {
      _markers[markerId] = marker;
    });
    
    // Smoothly animate camera to keep partner in view if they move significantly
    _mapController?.animateCamera(CameraUpdate.newLatLng(_partnerPos!));
  }

  @override
  void dispose() {
    _partnerLocationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking: ${widget.partnerRole == 'worker' ? 'Worker' : 'Client'}',
          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.navyDarkest),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMarkers();
            },
            markers: Set<Marker>.of(_markers.values),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            style: _mapStyle, // Use a premium dark style
          ),
          
          // Bottom Info Overlay
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.partnerRole == 'worker' ? Colors.blue[50] : Colors.red[50],
                        child: Icon(
                          widget.partnerRole == 'worker' ? Icons.pedal_bike : Icons.person_pin_circle,
                          color: widget.partnerRole == 'worker' ? Colors.blue : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.partnerRole == 'worker' ? 'Worker is on the way' : 'Client is at pickup',
                              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Live GPS Updates Enabled',
                              style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simplified premium dark style
  static const String _mapStyle = '''
  [
    {
      "featureType": "all",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#7c93a3"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#193341"}]
    }
  ]
  ''';
}
