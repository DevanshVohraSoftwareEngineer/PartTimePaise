import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/futuristic_background.dart';
import '../widgets/glass_card.dart';
import '../config/theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Discover', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            letterSpacing: -1, 
            fontSize: 24,
            color: textColor,
          )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Hub",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    Icon(
                      Icons.lightbulb_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Curated campus experiences",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 30),
                _buildViralCard(
                  context,
                  title: 'AI Meal Scanner',
                  subtitle: 'Intelligent nutrition analysis from photos',
                  icon: Icons.qr_code_scanner_rounded, // Black scanner symbol
                  gradient: isDark ? [Colors.white24, Colors.white10] : [Colors.black, Color(0xFF2C2C2E)],
                  isDark: isDark,
                  onTap: () {
                    context.push('/calorie-counter');
                  },
                ),
                const SizedBox(height: 20),
                _buildViralCard(
                  context,
                  title: 'Campus Dating',
                  subtitle: 'Discovery meaningful connections',
                  icon: Icons.favorite, // Black shining heart
                  gradient: isDark ? [Colors.white24, Colors.white10] : [Colors.black, Color(0xFF2C2C2E)],
                  isDark: isDark,
                  onTap: () {
                    _showComingSoon(context, 'Quick Dating');
                  },
                ),
                const SizedBox(height: 20),
                _buildViralCard(
                  context,
                  title: 'Elite Events',
                  subtitle: 'Premium campus access & networking',
                  icon: Icons.calendar_month_rounded, // Calendar icon
                  gradient: isDark ? [Colors.white24, Colors.white10] : [Colors.black, Color(0xFF2C2C2E)],
                  isDark: isDark,
                  onTap: () {
                    _showComingSoon(context, 'Campus Events');
                  },
                ),
                const SizedBox(height: 100), // Bottom padding for navbar
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.luxeDarkGrey : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? AppTheme.luxeMediumGrey : AppTheme.luxeLightGrey, width: 1),
        ),
        title: Text('$feature 👀', style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        )),
        content: Text('$feature is currently trending and will be available soon!', 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('NOTIFIED', style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildViralCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final Color titleColor = isDark ? Colors.white : Colors.black;
    final Color subColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.12) : Colors.black, // Solid black in light mode
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon, 
                    color: Colors.white, // White icon on black background
                    size: 28
                  ),
                ),
                // Subtle decorative background icon matching theme
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              color: isDark ? Colors.white24 : Colors.black26, 
              size: 14
            ),
          ],
        ),
      ),
    );
  }
}
