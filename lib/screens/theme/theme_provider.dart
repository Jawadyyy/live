import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AnimationController? _animationController;
  late Animation<double> _animation;

  ThemeMode get themeMode => _themeMode;

  // Light theme with more customization
  ThemeData get lightTheme => ThemeData.light().copyWith(
    colorScheme: ColorScheme.light(
      primary: Colors.blue.shade700,
      secondary: Colors.blueAccent.shade400,
      surface: Colors.white,
      background: Colors.grey.shade50,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue.shade700,
      unselectedItemColor: Colors.grey.shade600,
      elevation: 8,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
  );

  // Dark theme with more customization
  ThemeData get darkTheme => ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: Colors.blueAccent.shade200,
      secondary: Colors.lightBlueAccent.shade200,
      surface: Colors.grey.shade900,
      background: Colors.grey.shade800,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey.shade900,
      selectedItemColor: Colors.blueAccent.shade200,
      unselectedItemColor: Colors.grey.shade500,
      elevation: 8,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade900,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.white.withOpacity(0.1),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blueAccent.shade200,
      foregroundColor: Colors.black,
      elevation: 4,
    ),
  );

  // Get the current theme with animation support
  ThemeData getTheme(BuildContext context) {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;

    // Create a copy of the appropriate theme
    final baseTheme = isDarkMode ? darkTheme : lightTheme;

    // Apply animation if available
    if (_animationController != null && _animationController!.isAnimating) {
      final otherTheme = isDarkMode ? lightTheme : darkTheme;

      return baseTheme.copyWith(
        colorScheme: ColorScheme.lerp(
          otherTheme.colorScheme,
          baseTheme.colorScheme,
          _animation.value,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color.lerp(
            otherTheme.appBarTheme.backgroundColor,
            baseTheme.appBarTheme.backgroundColor,
            _animation.value,
          ),
          foregroundColor: Color.lerp(
            otherTheme.appBarTheme.foregroundColor,
            baseTheme.appBarTheme.foregroundColor,
            _animation.value,
          ),
          elevation: baseTheme.appBarTheme.elevation,
          shadowColor: Color.lerp(
            otherTheme.appBarTheme.shadowColor,
            baseTheme.appBarTheme.shadowColor,
            _animation.value,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color.lerp(
            otherTheme.bottomNavigationBarTheme.backgroundColor,
            baseTheme.bottomNavigationBarTheme.backgroundColor,
            _animation.value,
          ),
          selectedItemColor: Color.lerp(
            otherTheme.bottomNavigationBarTheme.selectedItemColor,
            baseTheme.bottomNavigationBarTheme.selectedItemColor,
            _animation.value,
          ),
          unselectedItemColor: Color.lerp(
            otherTheme.bottomNavigationBarTheme.unselectedItemColor,
            baseTheme.bottomNavigationBarTheme.unselectedItemColor,
            _animation.value,
          ),
        ),
      );
    }

    return baseTheme;
  }

  void initialize() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  // Toggle theme with animation
  Future<void> toggleTheme(bool? isDark, {TickerProvider? vsync}) async {
    final newMode =
        isDark == null
            ? ThemeMode.system
            : isDark
            ? ThemeMode.dark
            : ThemeMode.light;

    if (newMode == _themeMode) return;

    // If we have a vsync provider, animate the transition
    if (vsync != null) {
      _animationController?.dispose();
      _animationController = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 500),
      );

      _animation = CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      );

      // Start the animation
      await _animationController!.forward(from: 0);
    }

    _themeMode = newMode;
    notifyListeners();

    // Clean up after animation
    if (_animationController != null) {
      await _animationController!.forward();
      _animationController?.dispose();
      _animationController = null;
    }
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}
