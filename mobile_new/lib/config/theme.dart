import 'package:flutter/material.dart';

class AppTheme {
  // Electric Futuristic Scale
  static const Color electricDarkest = Color(0xFF000B1A);
  static const Color electricDark = Color(0xFF001F3F);
  static const Color electricMedium = Color(0xFF0074D9);
  static const Color electricLight = Color(0xFF7FDBFF);
  static const Color electricLightest = Color(0xFFE1F5FE);
  static const Color cyanAccent = Color(0xFF00FFFF);
  static const Color glassBlue = Color(0x33B3E5FC); // 20% opacity light blue
  
  // Branding Aliases
  static const Color primaryColor = electricMedium;
  
  // Accent Colors
  static const Color likeGreen = Color(0xFF2ECC40);
  static const Color nopeRed = Color(0xFFFF4136);
  static const Color superLikeBlue = Color(0xFF0074D9);
  static const Color boostGold = Color(0xFFFFDC00);
  static const Color electricPurple = Color(0xFFB10DC9);
  
  // Neutral Colors (Futuristic leans dark)
  static const Color white = Colors.white;
  static const Color grey50 = Color(0xFFF8F9FA);
  
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    final Color primary = isDark ? cyanAccent : electricMedium;
    final Color background = isDark ? electricDarkest : electricLightest;
    final Color surface = isDark ? const Color(0x1AFFFFFF) : const Color(0xCCFFFFFF); // Glassy

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: electricMedium,
        brightness: brightness,
        primary: primary,
        secondary: cyanAccent,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Always transparent for the background effect
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? white : electricDark),
        titleTextStyle: TextStyle(
          color: isDark ? white : electricDark,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? primary.withOpacity(0.3) : primary.withOpacity(0.1), 
            width: 1
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: primary.withOpacity(0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: _heading1Style(isDark),
        headlineMedium: _heading2Style(isDark),
        headlineSmall: _heading3Style(isDark),
        bodyLarge: _bodyLargeStyle(isDark),
        bodyMedium: _bodyMediumStyle(isDark),
        bodySmall: _bodySmallStyle(isDark),
      ),
    );
  }

  // Internal Helper Styles (Adaptive)
  static TextStyle _heading1Style(bool isDark) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1,
    color: isDark ? white : Colors.black,
    shadows: isDark ? [const Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54)] : null,
  );

  static TextStyle _heading2Style(bool isDark) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: isDark ? white : Colors.black,
    shadows: isDark ? [const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black54)] : null,
  );

  static TextStyle _heading3Style(bool isDark) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: isDark ? white : Colors.black,
    shadows: isDark ? [const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black54)] : null,
  );

  static TextStyle _bodyLargeStyle(bool isDark) => TextStyle(
    fontSize: 16,
    color: isDark ? white.withOpacity(0.9) : Colors.black87,
  );

  static TextStyle _bodyMediumStyle(bool isDark) => TextStyle(
    fontSize: 14,
    color: isDark ? white.withOpacity(0.8) : Colors.black87,
  );

  static TextStyle _bodySmallStyle(bool isDark) => TextStyle(
    fontSize: 12,
    color: isDark ? white.withOpacity(0.7) : Colors.black54,
  );

  // Static Getters for UI Code (Legacy Support - Non-const)
  static TextStyle get heading1 => const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1);
  static TextStyle get heading2 => const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static TextStyle get heading3 => const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get bodyLarge => const TextStyle(fontSize: 16);
  static TextStyle get bodyMedium => const TextStyle(fontSize: 14);
  static TextStyle get bodySmall => const TextStyle(fontSize: 12);
  static TextStyle get caption => const TextStyle(fontSize: 12);

  // Constants to fix build errors
  static const Color navyMedium = electricMedium;
  static const Color navyDark = electricDark;
  static const Color navyDarkest = electricDarkest;
  static const Color navyLightest = electricLightest;
  static const Color navyLight = electricLight;

  // Adaptive Neutrals
  static Color getAdaptiveGrey700(BuildContext context) => 
    Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : const Color(0xFF616161);
  
  static Color getAdaptiveGrey600(BuildContext context) => 
    Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF757575);

  static const Color grey900 = Color(0xFF111111);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color navyMediumPastel = Color(0xFFE1F5FE); 
}
