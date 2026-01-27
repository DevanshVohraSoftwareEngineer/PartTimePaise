import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/haptics.dart';

class SlideToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final String label;
  final Color baseColor;
  final Color confirmColor;

  const SlideToConfirm({
    Key? key,
    required this.onConfirm,
    this.label = 'SLIDE TO ACCEPT',
    this.baseColor = const Color(0xFF333333),
    this.confirmColor = AppTheme.likeGreen,
  }) : super(key: key);

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  late AnimationController _controller;
  late Animation<double> _animation;
  final double _handleSize = 56.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxWidth) {
    setState(() {
      _dragValue += details.primaryDelta! / (maxWidth - _handleSize);
      _dragValue = _dragValue.clamp(0.0, 1.0);
    });
    
    // Light haptic feedback as user slides
    if (_dragValue > 0.1 && _dragValue < 0.9) {
      // Logic to trigger only once per 10% movement
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragValue > 0.9) {
      // Confirmed!
      AppHaptics.heavy();
      widget.onConfirm();
      setState(() {
        _dragValue = 1.0;
      });
    } else {
      // Snap back
      _animation = Tween<double>(begin: _dragValue, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      )..addListener(() {
          setState(() {
            _dragValue = _animation.value;
          });
        });
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final handleOffset = _dragValue * (maxWidth - _handleSize);

        return Container(
          height: 64,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.baseColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Stack(
            children: [
              // Background Progress
              Positioned.fill(
                child: Row(
                  children: [
                    Container(
                      width: handleOffset + (_handleSize / 2),
                      decoration: BoxDecoration(
                        color: widget.confirmColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Centered Label
              Center(
                child: Opacity(
                  opacity: (1.0 - _dragValue).clamp(0.1, 1.0),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),

              // The Draggable Handle
              Positioned(
                left: handleOffset,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxWidth),
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.white, widget.confirmColor, _dragValue),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.confirmColor.withOpacity(0.5 * _dragValue),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _dragValue > 0.9 ? Icons.check : Icons.arrow_forward_ios,
                      color: _dragValue > 0.5 ? Colors.white : widget.baseColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
