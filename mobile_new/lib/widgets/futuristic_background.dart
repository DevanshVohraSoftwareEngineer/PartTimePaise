import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../managers/theme_settings_provider.dart';

class FuturisticBackground extends ConsumerStatefulWidget {
  final Widget child;
  const FuturisticBackground({super.key, required this.child});

  @override
  ConsumerState<FuturisticBackground> createState() => _FuturisticBackgroundState();
}

class _FuturisticBackgroundState extends ConsumerState<FuturisticBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Bolt> _bolts = [];
  final List<CashToken> _cashTokens = [];
  final math.Random _random = math.Random();
  double _flashOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    final theme = ref.read(themeSettingsProvider).backgroundTheme;

    if (theme == BackgroundTheme.thunder) {
      _updateBolts();
    } else {
      _updateCashTokens();
    }
  }

  void _updateBolts() {
    if (_random.nextDouble() < 0.02) {
      _triggerStrike();
    }

    setState(() {
      _bolts.removeWhere((bolt) => bolt.isExpired);
      for (var bolt in _bolts) {
        bolt.age += 0.05;
      }
      _flashOpacity *= 0.85;
      if (_flashOpacity < 0.01) _flashOpacity = 0.0;
    });
  }

  void _updateCashTokens() {
    if (_random.nextDouble() < 0.1) {
      _spawnCashToken();
    }

    setState(() {
      _cashTokens.removeWhere((token) => token.y > MediaQuery.of(context).size.height + 50);
      for (var token in _cashTokens) {
        token.y += token.speed;
        token.rotation += token.rotationSpeed;
      }
      _flashOpacity = 0.0; // No flash for cash
    });
  }

  void _triggerStrike() {
    final startX = _random.nextDouble() * MediaQuery.of(context).size.width;
    _bolts.add(Bolt(
      startX: startX,
      points: _generateFractalPath(startX, 0, MediaQuery.of(context).size.height),
      opacity: 1.0,
    ));
    _flashOpacity = 0.3;
  }

  void _spawnCashToken() {
    final startX = _random.nextDouble() * MediaQuery.of(context).size.width;
    final String symbol = _random.nextBool() ? "₹" : "\$";
    _cashTokens.add(CashToken(
      x: startX,
      y: -50.0,
      symbol: symbol,
      speed: _random.nextDouble() * 3 + 2,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      size: _random.nextDouble() * 10 + 15,
    ));
  }

  List<Offset> _generateFractalPath(double x, double y, double maxHeight) {
    List<Offset> path = [Offset(x, y)];
    double curX = x;
    double curY = y;
    
    while (curY < maxHeight) {
      double nextY = curY + (_random.nextDouble() * 40 + 20);
      double nextX = curX + (_random.nextDouble() - 0.5) * 80;
      path.add(Offset(nextX, nextY));
      curX = nextX;
      curY = nextY;
    }
    return path;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = ref.watch(themeSettingsProvider).backgroundTheme;

    return Stack(
      children: [
        // 1. Background Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme == BackgroundTheme.thunder
                ? (isDark 
                    ? [const Color(0xFF000B1A), const Color(0xFF001F3F), const Color(0xFF000B1A)]
                    : [const Color(0xFFE1F5FE), const Color(0xFFB3E5FC), const Color(0xFFE1F5FE)])
                : (isDark
                    ? [const Color(0xFF0B1A00), const Color(0xFF1F3F00), const Color(0xFF0B1A00)]
                    : [const Color(0xFFF1FCE1), const Color(0xFFE5FCB3), const Color(0xFFF1FCE1)]),
            ),
          ),
        ),
        
        // 2. Full-screen Flash Overlay
        IgnorePointer(
          child: Container(
            color: Colors.white.withOpacity(_flashOpacity),
          ),
        ),

        // 3. Animation Layer
        IgnorePointer(
          child: CustomPaint(
            painter: theme == BackgroundTheme.thunder 
                ? ProperLightningPainter(_bolts) 
                : CashShowerPainter(_cashTokens),
            size: Size.infinite,
          ),
        ),

        // 4. Subtle Overlay for Legibility
        IgnorePointer(
          child: Container(
            color: isDark 
                ? Colors.black.withOpacity(0.4) 
                : Colors.white.withOpacity(0.1),
          ),
        ),

        // 5. Child content
        widget.child,
      ],
    );
  }
}

class CashToken {
  double x;
  double y;
  final String symbol;
  final double speed;
  double rotation = 0.0;
  final double rotationSpeed;
  final double size;

  CashToken({
    required this.x,
    required this.y,
    required this.symbol,
    required this.speed,
    required this.rotationSpeed,
    required this.size,
  });
}

class CashShowerPainter extends CustomPainter {
  final List<CashToken> tokens;

  CashShowerPainter(this.tokens);

  @override
  void paint(Canvas canvas, Size size) {
    for (var token in tokens) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: token.symbol,
          style: TextStyle(
            color: Colors.green.withOpacity(0.4),
            fontSize: token.size,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(token.x, token.y);
      canvas.rotate(token.rotation);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CashShowerPainter oldDelegate) => true;
}

class Bolt {
  final double startX;
  final List<Offset> points;
  double opacity;
  double age = 0.0;

  Bolt({required this.startX, required this.points, required this.opacity});

  bool get isExpired => age > 1.0;
}

class ProperLightningPainter extends CustomPainter {
  final List<Bolt> bolts;

  ProperLightningPainter(this.bolts);

  @override
  void paint(Canvas canvas, Size size) {
    for (var bolt in bolts) {
      final alpha = (1.0 - bolt.age).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, alpha * 0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final glowPaint = Paint()
        ..color = Color.fromRGBO(0, 255, 255, alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..strokeWidth = 6.0;

      final path = Path();
      if (bolt.points.isNotEmpty) {
        path.moveTo(bolt.points[0].dx, bolt.points[0].dy);
        for (int i = 1; i < bolt.points.length; i++) {
          path.lineTo(bolt.points[i].dx, bolt.points[i].dy);
        }
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ProperLightningPainter oldDelegate) => true;
}
