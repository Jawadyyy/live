import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  // Initialize with system preference
  void initialize() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  // Toggle between light/dark/system
  void toggleTheme(bool? isDark) {
    if (isDark == null) {
      // Set to system theme
      _themeMode = ThemeMode.system;
    } else {
      // Set to specific theme
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  // Check if dark mode is enabled (considering system preference)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Get the platform brightness
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
