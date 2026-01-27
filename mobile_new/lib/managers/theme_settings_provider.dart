import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackgroundTheme { thunder, cash }

class ThemeSettings {
  final BackgroundTheme backgroundTheme;

  ThemeSettings({required this.backgroundTheme});

  ThemeSettings copyWith({BackgroundTheme? backgroundTheme}) {
    return ThemeSettings(
      backgroundTheme: backgroundTheme ?? this.backgroundTheme,
    );
  }
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  static const String _key = 'background_theme';

  ThemeSettingsNotifier() : super(ThemeSettings(backgroundTheme: BackgroundTheme.cash)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_key);
    if (themeString != null) {
      final theme = BackgroundTheme.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => BackgroundTheme.cash,
      );
      state = state.copyWith(backgroundTheme: theme);
    }
  }

  Future<void> setBackgroundTheme(BackgroundTheme theme) async {
    state = state.copyWith(backgroundTheme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }

  void toggleTheme() {
    final newTheme = state.backgroundTheme == BackgroundTheme.thunder 
        ? BackgroundTheme.cash 
        : BackgroundTheme.thunder;
    setBackgroundTheme(newTheme);
  }
}

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  return ThemeSettingsNotifier();
});
