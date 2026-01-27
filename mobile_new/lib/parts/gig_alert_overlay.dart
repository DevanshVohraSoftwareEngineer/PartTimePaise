import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parttimepaise/config/theme.dart';
import 'package:parttimepaise/data_types/gig_request.dart';
import 'package:parttimepaise/data_types/task.dart';
import 'package:parttimepaise/services/gig_service.dart';
import 'package:parttimepaise/services/supabase_service.dart';
import 'package:geolocator/geolocator.dart'; // Added import

class GigAlertOverlay extends ConsumerStatefulWidget {
  final GigRequest request;
  final VoidCallback onDismiss;

  const GigAlertOverlay({
    Key? key,
    required this.request,
    required this.onDismiss,
  }) : super(key: key);

  @override
  ConsumerState<GigAlertOverlay> createState() => _GigAlertOverlayState();
}

class _GigAlertOverlayState extends ConsumerState<GigAlertOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Task? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    final supabase = ref.read(supabaseServiceProvider);
    final taskData = await supabase.client
        .from('tasks')
        .select()
        .eq('id', widget.request.taskId)
        .single();
    
    if (mounted) {
      setState(() {
        _task = Task.fromJson(taskData);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    try {
      await ref.read(gigServiceProvider).acceptGig(widget.request.id);
      widget.onDismiss();
      // Navigate to task details or active gig screen
      // context.push('/active-gig/${widget.request.taskId}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept gig: $e')),
      );
    }
  }

  Future<void> _handleReject() async {
    await ref.read(gigServiceProvider).rejectGig(widget.request.id);
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();

    return Material(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NEW GIG',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                      Text(
                        '₹${_task?.budget.toInt()}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Map Placeholder (Premium style)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=28.7041,77.1025&zoom=14&size=600x300&key=YOUR_API_KEY'), // Placeholder
                      fit: BoxFit.cover,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const  Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
                
                const SizedBox(height: 20),

                // Title & Distance
                // Title & Distance
                Text(
                  _task?.title ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FutureBuilder<Position>(
                  future: Geolocator.getCurrentPosition(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && _task?.pickupLat != null && _task?.pickupLng != null) {
                       final dist = Geolocator.distanceBetween(
                          snapshot.data!.latitude,
                          snapshot.data!.longitude,
                          _task!.pickupLat!,
                          _task!.pickupLng!,
                       );
                       return Text(
                        '${(dist / 1000).toStringAsFixed(1)} km away',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getAdaptiveGrey600(context),
                        ),
                      );
                    }
                    return Text(
                      _task?.distanceMeters != null 
                          ? '${(_task!.distanceMeters! / 1000).toStringAsFixed(1)} km away (Est.)' 
                          : 'Calculating distance...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.getAdaptiveGrey600(context),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Action Slider / Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleReject,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
