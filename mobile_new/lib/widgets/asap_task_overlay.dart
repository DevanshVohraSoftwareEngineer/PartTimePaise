import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../services/audio_service.dart';
import '../utils/haptics.dart';
import 'countdown_timer.dart';

import '../widgets/slide_to_confirm.dart';

class ASAPTaskOverlay extends StatefulWidget {
  final String taskId;
  final String title;
  final String budget;
  final String urgency;
  final DateTime expiresAt;
  final String? distance;
  final String? pickupLocation;
  final String? dropLocation;
  final int? estimatedTime;
  final Future<void> Function() onAccept;
  final VoidCallback onReject;

  const ASAPTaskOverlay({
    super.key,
    required this.taskId,
    required this.title,
    required this.budget,
    this.urgency = 'asap',
    required this.expiresAt,
    this.distance,
    this.pickupLocation,
    this.dropLocation,
    this.estimatedTime,
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

    // Track as realtime viewer
    SupabaseService.instance.updateRealtimeViewers(widget.taskId, 1);

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
    SupabaseService.instance.updateRealtimeViewers(widget.taskId, -1);
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dark Map Background (Ambient)
          Opacity(
            opacity: 0.2,
            child: Image.network(
              'https://maps.googleapis.com/maps/api/staticmap?center=28.7041,77.1025&zoom=14&size=600x1200&style=feature:all|element:all|saturation:-100|invert_lightness:true&key=YOUR_API_KEY',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Heading Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.likeGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.likeGreen.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on, color: AppTheme.likeGreen, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'NEW ${widget.urgency.toUpperCase()} TASK',
                        style: const TextStyle(color: AppTheme.likeGreen, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // 2. LARGE EARNINGS (Top priority focal point)
                Text(
                  '₹${double.parse(widget.budget).toInt()}',
                  style: const TextStyle(
                    fontSize: 100, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white, 
                    height: 1.0,
                    letterSpacing: -4,
                  ),
                ),
                const Text(
                  'POTENTIAL EARNINGS',
                  style: TextStyle(fontSize: 14, color: Colors.white54, letterSpacing: 3, fontWeight: FontWeight.w900),
                ),
                
                const Spacer(flex: 1),
                
                // 3. TASK LOCATION CARD (Middle)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 0),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationRow(
                          icon: Icons.circle,
                          iconColor: Colors.blueAccent,
                          label: 'PICKUP',
                          address: widget.pickupLocation ?? 'Current Location Area',
                          showLine: true,
                        ),
                        const SizedBox(height: 12),
                        _buildLocationRow(
                          icon: Icons.location_on,
                          iconColor: AppTheme.nopeRed,
                          label: 'DROP',
                          address: widget.dropLocation ?? widget.title,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Colors.white12, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              Icons.directions_run,
                              _realDistanceMeters != null 
                                ? '${(_realDistanceMeters! / 1000).toStringAsFixed(1)} KM'
                                : (widget.distance ?? '-- KM'),
                              'DISTANCE',
                            ),
                            _buildInfoItem(
                              Icons.timer_outlined,
                              '${widget.estimatedTime ?? 15} MIN',
                              'EST. TIME',
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer, color: Colors.orange, size: 16),
                                    const SizedBox(width: 6),
                                    CountdownTimer(
                                      expiresAt: widget.expiresAt,
                                      textStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'EXPIRES IN',
                                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // 4. ACTION BAR (Bottom)
                // ✨ Designed like an incoming call screen
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: _isAccepting 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.likeGreen))
                    : Column(
                        children: [
                          SlideToConfirm(
                            onConfirm: _processAccept,
                            label: 'SLIDE TO ACCEPT',
                            confirmColor: AppTheme.likeGreen,
                          ),
                          const SizedBox(height: 20),
                          SlideToConfirm(
                            onConfirm: _processDismiss,
                            label: 'SLIDE TO REJECT',
                            confirmColor: Colors.redAccent.withOpacity(0.8),
                            baseColor: Colors.white10,
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
    bool showLine = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            if (showLine)
              Container(
                width: 2,
                height: 30,
                color: Colors.white10,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
