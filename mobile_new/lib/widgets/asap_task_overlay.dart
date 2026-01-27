import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../services/audio_service.dart';
import '../utils/haptics.dart';
import '../widgets/call_slider.dart';

class ASAPTaskOverlay extends StatefulWidget {
  final String taskId;
  final String title;
  final String budget;
  final DateTime expiresAt;
  final String? distance;
  final Future<void> Function() onAccept;
  final VoidCallback onReject;

  const ASAPTaskOverlay({
    super.key,
    required this.taskId,
    required this.title,
    required this.budget,
    required this.expiresAt,
    this.distance,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<ASAPTaskOverlay> createState() => _ASAPTaskOverlayState();
}

class _ASAPTaskOverlayState extends State<ASAPTaskOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isAccepting = false;
  double? _realDistanceMeters;

  @override
  void initState() {
    super.initState();
    audioService.startAlarm();
    AppHaptics.alert();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    
    _controller.forward();
    
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _isAccepting) {
        timer.cancel();
      } else {
        AppHaptics.medium();
      }
    });

    _calculateRealDistance();
  }

  Future<void> _calculateRealDistance() async {
    try {
      final supabase = SupabaseService.instance.client;
      final taskData = await supabase.from('tasks').select('pickup_lat, pickup_lng').eq('id', widget.taskId).single();
      
      if (taskData['pickup_lat'] != null && taskData['pickup_lng'] != null) {
        final pos = await Geolocator.getCurrentPosition();
        final dist = Geolocator.distanceBetween(
          pos.latitude, 
          pos.longitude, 
          taskData['pickup_lat'], 
          taskData['pickup_lng']
        );
        
        if (mounted) {
          setState(() {
            _realDistanceMeters = dist;
          });
        }
      }
    } catch (e) {
      print('Error calculating overlay distance: $e');
    }
  }

  @override
  void dispose() {
    audioService.stopAlarm();
    _controller.dispose();
    super.dispose();
  }

  void _processDismiss() {
    audioService.stopAlarm();
    _controller.reverse().then((_) {
      widget.onReject();
    });
  }

  Future<void> _processAccept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);
    audioService.stopAlarm();
    
    try {
      await widget.onAccept();
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Map Background
          Opacity(
            opacity: 0.3,
            child: Image.network(
              'https://maps.googleapis.com/maps/api/staticmap?center=28.7041,77.1025&zoom=14&size=600x1200&style=feature:all|element:all|saturation:-100|visibility:simplified&key=YOUR_API_KEY',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
            ),
          ),
          
          // 2. Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Spacer(),
                
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 30, spreadRadius: 10),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'ASAP GIG ALERT',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        Text(
                          '₹${double.parse(widget.budget).toInt()}',
                          style: const TextStyle(
                            fontSize: 84, 
                            fontWeight: FontWeight.w900, 
                            color: Colors.white, 
                            height: 1.0,
                            letterSpacing: -2,
                          ),
                        ),
                        const Text(
                          'ESTIMATED EARNINGS',
                          style: TextStyle(fontSize: 14, color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                               Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.near_me, color: Colors.greenAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _realDistanceMeters != null 
                                      ? '${(_realDistanceMeters! / 1000).toStringAsFixed(1)} KM AWAY'
                                      : (widget.distance ?? 'Nearby'),
                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _isAccepting 
                    ? const CircularProgressIndicator(color: Colors.greenAccent)
                    : CallSlider(
                        onAccept: _processAccept,
                        onReject: _processDismiss,
                        label: 'SLIDE TO ACCEPT GIG',
                      ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
