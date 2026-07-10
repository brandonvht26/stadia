import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode');
    
    switch (themeString) {
      case 'light':
        themeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeNotifier.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeNotifier.value = ThemeMode.system;
        break;
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeString = 'system';
        break;
    }
    
    await prefs.setString('theme_mode', themeString);
  }

  static Future<void> setThemeAndSync(
    ThemeMode mode, {
    Function(Map<String, dynamic>)? onSyncToProfile,
  }) async {
    await setTheme(mode);
    if (onSyncToProfile != null) {
      String themeString;
      switch (mode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
        default:
          themeString = 'system';
          break;
      }
      onSyncToProfile({'theme_preference': themeString});
    }
  }
}
