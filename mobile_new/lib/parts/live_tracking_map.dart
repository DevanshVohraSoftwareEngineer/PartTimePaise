import 'package:flutter/material.dart';
import '../config/theme.dart';

class LiveTrackingMap extends StatefulWidget {
  final String status; // 'assigned', 'in_progress', 'completed'
  final double progress; // 0.0 to 1.0 (completion)

  const LiveTrackingMap({
    super.key,
    required this.status,
    this.progress = 0.0,
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simulate map integration with a high-quality styling
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3FD), // Map water/bg color
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Map Grid / Roads (Visual Decoration)
          Positioned.fill(
            child: CustomPaint(
              painter: MapGridPainter(),
            ),
          ),

          // 2. Path Line
          Positioned.fill(
            child: Center(
              child: Container(
                height: 4,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          // 3. Progress Line
          Positioned.fill(
            child: Center(
              child:  Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    width: 200,
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      width: 200 * _getEffectiveProgress(),
                      height: 4,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Pickup Point (Left)
          const Positioned(
            left: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store, color: AppTheme.navyMedium, size: 28),
                  SizedBox(height: 4),
                  Text("Tasks", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 5. Dropoff Point (Right)
          const Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, color: AppTheme.navyMedium, size: 28),
                  SizedBox(height: 4),
                  Text("You", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 6. Moving Worker Avatar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            // Calculate left position based on progress (approximate centering)
            left: (MediaQuery.of(context).size.width * 0.5 - 100) + (200 * _getEffectiveProgress()) - 20, 
            top: 90, // Vertically centered roughly (250/2 - avatar half)
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor().withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: _getStatusColor(),
                  child: const Icon(Icons.two_wheeler, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          
          // 7. Status Banner
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.watch_later_outlined, color: _getStatusColor(), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _getStatusSubtitle(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  double _getEffectiveProgress() {
    // If status is 'completed', force 100%
    if (widget.status == 'completed') return 1.0;
    if (widget.status == 'open') return 0.0;
    // For assigned/in_progress, use the widget.progress or a default
    // Simulated progress based on status if 0 is passed
    if (widget.progress == 0) {
      if (widget.status == 'assigned') return 0.2;
      if (widget.status == 'in_progress') return 0.6;
    }
    return widget.progress;
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case 'assigned':
        return AppTheme.superLikeBlue;
      case 'in_progress':
        return AppTheme.boostGold;
      case 'completed':
        return AppTheme.likeGreen;
      default:
        return AppTheme.grey500;
    }
  }

  String _getStatusTitle() {
    switch (widget.status) {
      case 'open': return 'Waiting for Worker';
      case 'assigned': return 'Worker is on the way';
      case 'in_progress': return 'Task in progress';
      case 'completed': return 'Task Completed';
      default: return 'Status Unknown';
    }
  }

  String _getStatusSubtitle() {
    switch (widget.status) {
      case 'open': return 'Broadcasting to nearby workers...';
      case 'assigned': return 'Arriving in ~10 mins';
      case 'in_progress': return 'Work started 15 mins ago';
      case 'completed': return 'Job done! Please review.';
      default: return '';
    }
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 1.0;

    // Draw grid
    const spacing = 30.0;
    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Draw some random "roads"
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width * 0.3, size.height * 0.6), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.6), Offset(size.width, size.height * 0.3), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
