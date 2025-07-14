import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF7C56E1),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF7C56E1)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.black87),
      displayMedium: TextStyle(color: Colors.black87),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF7C56E1)),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(const Color(0xFF7C56E1)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(const Color(0xFF7C56E1)),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFF7C56E1)),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF7C56E1),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      color: Colors.black.withOpacity(0.5),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
    ),
    cardTheme: CardThemeData(
      color: Colors.black.withOpacity(0.3),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF7C56E1)),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(const Color(0xFF7C56E1)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(const Color(0xFF7C56E1)),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFF7C56E1)),
        ),
      ),
    ),
    dialogBackgroundColor: Colors.black.withOpacity(0.6),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.black.withOpacity(0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );
}
