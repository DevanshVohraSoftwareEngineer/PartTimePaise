import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';

class AuthSuccessScreen extends ConsumerWidget {
  final String title;
  final String message;
  final String buttonText;
  final String targetRoute;

  const AuthSuccessScreen({
    super.key,
    this.title = 'Successful!',
    this.message = 'Your password has been reset successfully. You can now log in with your new password.',
    this.buttonText = 'GO TO LOGIN',
    this.targetRoute = '/login',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Success Icon Container
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.likeGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppTheme.likeGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent,
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Success Text
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.navyDark,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 64),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Password reset successfully!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      context.go(targetRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricMedium,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Logo or App Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on, size: 16, color: AppTheme.electricMedium),
                    const SizedBox(width: 4),
                    Text(
                      'PARTTIME PAISE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                        color: isDark ? Colors.white38 : Colors.black26,
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
