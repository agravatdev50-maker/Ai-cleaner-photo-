import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

/// Persists and exposes the user's theme preference.
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system; // default until prefs load
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefThemeMode);
    if (saved == 'light') state = ThemeMode.light;
    else if (saved == 'dark') state = ThemeMode.dark;
    else state = ThemeMode.system;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    String val;
    switch (mode) {
      case ThemeMode.light:  val = 'light'; break;
      case ThemeMode.dark:   val = 'dark';  break;
      default:               val = 'system';
    }
    await prefs.setString(AppConstants.prefThemeMode, val);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
