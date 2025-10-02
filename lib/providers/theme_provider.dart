import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translations.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  static const String _themeKey = 'theme_mode';

  AppThemeMode get themeMode => _themeMode;

  ThemeMode get systemThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode {
    if (_themeMode == AppThemeMode.system) {
      // This will be overridden by system brightness in actual usage
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }

  bool get isLightMode => _themeMode == AppThemeMode.light;
  bool get isSystemMode => _themeMode == AppThemeMode.system;

  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == savedTheme,
          orElse: () => AppThemeMode.system,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Set theme mode and save to preferences
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    debugPrint('ThemeProvider: Changing theme from $_themeMode to $mode');
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
      debugPrint('ThemeProvider: Saved theme preference: $mode');
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Toggle between light and dark (skip system for manual toggle)
  Future<void> toggleTheme() async {
    AppThemeMode newMode;

    switch (_themeMode) {
      case AppThemeMode.system:
      case AppThemeMode.light:
        newMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        newMode = AppThemeMode.light;
        break;
    }

    await setThemeMode(newMode);
  }

  /// Get next theme mode for cycling through options
  AppThemeMode getNextThemeMode() {
    switch (_themeMode) {
      case AppThemeMode.system:
        return AppThemeMode.light;
      case AppThemeMode.light:
        return AppThemeMode.dark;
      case AppThemeMode.dark:
        return AppThemeMode.system;
    }
  }

  /// Cycle through all theme modes (system -> light -> dark -> system)
  Future<void> cycleThemeMode() async {
    final nextMode = getNextThemeMode();
    debugPrint('ThemeProvider: Cycling from $_themeMode to $nextMode');
    await setThemeMode(nextMode);
  }

  /// Get display name for current theme mode
  String getThemeModeDisplayName([String? languageCode]) {
    final lang = languageCode ?? 'en'; // Default to English if no language provided
    switch (_themeMode) {
      case AppThemeMode.system:
        return Translations.get('theme_system', lang);
      case AppThemeMode.light:
        return Translations.get('theme_light', lang);
      case AppThemeMode.dark:
        return Translations.get('theme_dark', lang);
    }
  }

  /// Get icon for current theme mode
  IconData getThemeModeIcon() {
    switch (_themeMode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.brightness_7;
      case AppThemeMode.dark:
        return Icons.brightness_3;
    }
  }
}