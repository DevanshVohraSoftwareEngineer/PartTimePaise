import 'package:flutter/material.dart';

class AppTheme {
  // Apple Luxury Scale (Monochrome)
  static const Color luxeBlack = Color(0xFF000000);
  static const Color luxeDarkGrey = Color(0xFF1C1C1E);
  static const Color luxeMediumGrey = Color(0xFF2C2C2E);
  static const Color luxeLightGrey = Color(0xFFE5E5EA);
  static const Color luxeWhite = Color(0xFFFFFFFF);
  
  // Branding Aliases
  static const Color primaryColor = luxeBlack;
  
  // Accent Colors (Sophisticated)
  static const Color likeGreen = Color(0xFF34C759); // Apple Green
  static const Color nopeRed = Color(0xFFFF3B30);   // Apple Red
  static const Color superLikeBlue = Color(0xFF007AFF); // Apple Blue
  static const Color boostGold = Color(0xFFFFD60A);    // Apple Gold
  static const Color electricPurple = Color(0xFFAF52DE); // Apple Purple
  
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    final Color primary = isDark ? luxeWhite : luxeBlack;
    final Color background = isDark ? luxeBlack : luxeWhite;
    final Color surface = isDark ? luxeDarkGrey : luxeWhite;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      iconTheme: IconThemeData(color: primary),
      colorScheme: ColorScheme.fromSeed(
        seedColor: luxeBlack,
        brightness: brightness,
        primary: primary,
        secondary: isDark ? luxeLightGrey : luxeDarkGrey,
        surface: surface,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        titleTextStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        subtitleTextStyle: TextStyle(
          color: primary.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, // Luxury often uses flat borders
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? luxeMediumGrey : luxeLightGrey,
            width: 1
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? luxeBlack : luxeWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0, // Luxury is flat and clean
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? luxeDarkGrey : const Color(0xFFF2F2F7),
        prefixIconColor: isDark ? luxeWhite.withOpacity(0.5) : luxeBlack.withOpacity(0.5),
        suffixIconColor: isDark ? luxeWhite.withOpacity(0.5) : luxeBlack.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: isDark ? luxeLightGrey : luxeMediumGrey),
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
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    color: isDark ? luxeWhite : luxeBlack,
  );

  static TextStyle _heading2Style(bool isDark) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: isDark ? luxeWhite : luxeBlack,
  );

  static TextStyle _heading3Style(bool isDark) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: isDark ? luxeWhite : luxeBlack,
  );

  static TextStyle _bodyLargeStyle(bool isDark) => TextStyle(
    fontSize: 17, // Apple Standard
    color: isDark ? luxeWhite.withOpacity(0.9) : luxeBlack.withOpacity(0.9),
  );

  static TextStyle _bodyMediumStyle(bool isDark) => TextStyle(
    fontSize: 15,
    color: isDark ? luxeWhite.withOpacity(0.7) : luxeBlack.withOpacity(0.7),
  );

  static TextStyle _bodySmallStyle(bool isDark) => TextStyle(
    fontSize: 13,
    color: isDark ? luxeWhite.withOpacity(0.5) : luxeBlack.withOpacity(0.5),
  );

  // Legacy/Helper Static Getters
  static TextStyle get heading1 => const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.5);
  static TextStyle get heading2 => const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1);
  static TextStyle get heading3 => const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.5);
  static TextStyle get bodyLarge => const TextStyle(fontSize: 17);
  static TextStyle get bodyMedium => const TextStyle(fontSize: 15);
  static TextStyle get bodySmall => const TextStyle(fontSize: 13);
  static TextStyle get caption => const TextStyle(fontSize: 12);

  // Constants to fix build errors (Mapping to new luxe palette)
  // These are legacy and should ideally be avoided in favor of Theme.of(context)
  static const Color navyMedium = luxeBlack;
  static const Color navyDark = luxeBlack;
  static const Color navyDarkest = luxeBlack;
  static const Color navyLightest = luxeWhite;
  static const Color navyLight = luxeLightGrey;
  
  // New Adaptive Getters
  static Color getPrimaryColor(BuildContext context) => 
    Theme.of(context).brightness == Brightness.dark ? luxeWhite : luxeBlack;

  static Color getSecondaryColor(BuildContext context) => 
    Theme.of(context).brightness == Brightness.dark ? luxeLightGrey : luxeDarkGrey;

  static const Color electricMedium = luxeBlack;
  static const Color electricDarkText = luxeBlack;
  static const Color cyanAccent = luxeWhite; // In Dark mode buttons/accents

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
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color navyMediumPastel = Color(0xFFE1F5FE); 
}
