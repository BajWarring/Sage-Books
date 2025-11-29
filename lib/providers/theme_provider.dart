import 'package:flutter/material.dart';
import 'package:sage/main.dart'; // Import main.dart to get 'prefs'

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Load the saved theme from SharedPreferences
  void loadTheme() {
    final theme = prefs.getString('theme') ?? 'system';
    switch (theme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // Set the new theme and save it
  void setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    prefs.setString('theme', themeMode.name);
    notifyListeners();
  }
}
