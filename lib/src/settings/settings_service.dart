import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _themeModeKey = 'theme_mode';

  Future<ThemeMode> themeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey);
    return ThemeMode.values[modeIndex ?? ThemeMode.dark.index];
  }

  Future<void> updateThemeMode(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, theme.index);
  }
}
