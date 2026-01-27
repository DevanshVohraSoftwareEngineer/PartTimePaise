import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final DateTime expiresAt;
  final TextStyle? textStyle;
  final Color? urgentColor;
  final Color? normalColor;

  const CountdownTimer({
    super.key,
    required this.expiresAt,
    this.textStyle,
    this.urgentColor,
    this.normalColor,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now().toUtc(); // Use UTC
    final expiresUtc = widget.expiresAt.isUtc ? widget.expiresAt : widget.expiresAt.toUtc();
    final remaining = expiresUtc.difference(now);
    
    if (mounted) {
      setState(() {
        _remaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Color _getColor() {
    if (_remaining.inMinutes < 10) {
      return widget.urgentColor ?? Colors.red;
    }
    return widget.normalColor ?? Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.inSeconds <= 0) {
      return Text(
        'EXPIRED',
        style: widget.textStyle?.copyWith(color: Colors.red) ?? 
               const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: widget.textStyle?.fontSize ?? 12,
          color: _getColor(),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(_remaining),
          style: widget.textStyle?.copyWith(color: _getColor()) ?? 
                 TextStyle(color: _getColor(), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
