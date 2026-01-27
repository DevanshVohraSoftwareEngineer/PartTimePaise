import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/haptics.dart';

class CallSlider extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final String? label;

  const CallSlider({
    super.key,
    required this.onAccept,
    required this.onReject,
    this.label,
  });

  @override
  State<CallSlider> createState() => _CallSliderState();
}

class _CallSliderState extends State<CallSlider> {
  double _dragX = 0;
  final double _threshold = 100;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAcceptOnly = widget.label != null;
    final Color backgroundColor = Theme.of(context).cardColor;
    final Color knobColor = _dragX > 0 
        ? Colors.greenAccent 
        : (_dragX < 0 ? (isAcceptOnly ? Colors.white10 : Colors.redAccent) : (isDark ? Colors.white : Colors.black));

    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background labels
          if (!isAcceptOnly)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Text('<<<< REJECT', style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Text('ACCEPT >>>>', style: TextStyle(color: Colors.greenAccent.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Text(
              widget.label!.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),

          // The Center Knob
          AnimatedPositioned(
            duration: _dragX == 0 ? const Duration(milliseconds: 300) : Duration.zero,
            left: isAcceptOnly 
                ? (10 + _dragX) // Start from left for ASAP
                : ((MediaQuery.of(context).size.width / 2) - 40 + _dragX - 24), // Centered for others
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_triggered) return;
                setState(() {
                  _dragX += details.delta.dx;
                  // Clamp
                  if (_dragX > (isAcceptOnly ? 250 : _threshold + 20)) _dragX = (isAcceptOnly ? 250 : _threshold + 20);
                  if (_dragX < 0 && isAcceptOnly) _dragX = 0;
                  if (_dragX < -_threshold - 20 && !isAcceptOnly) _dragX = -_threshold - 20;
                });

                if (_dragX >= (isAcceptOnly ? 200 : _threshold) && !_triggered) {
                  _triggered = true;
                  AppHaptics.heavy();
                  widget.onAccept();
                } else if (_dragX <= -_threshold && !isAcceptOnly && !_triggered) {
                  _triggered = true;
                  AppHaptics.medium();
                  widget.onReject();
                }
              },
              onHorizontalDragEnd: (details) {
                if (!_triggered) {
                  setState(() => _dragX = 0);
                }
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: knobColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: knobColor.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _dragX > 0 ? Icons.check : (_dragX < 0 ? Icons.close : (isAcceptOnly ? Icons.chevron_right : Icons.double_arrow)),
                  color: (isDark || _dragX != 0) ? Colors.black : Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
