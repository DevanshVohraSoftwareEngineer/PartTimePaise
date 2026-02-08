import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E).withOpacity(0.7)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor ?? (isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06)),
          width: 0.8,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: child,
    );
  }
}
