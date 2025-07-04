import 'package:flutter/material.dart';
import 'package:live/screens/intro/splash_screen.dart';
import 'package:live/screens/theme/app_theme.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //supabase setup
  await Supabase.initialize(
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhemxhYmtjd3dqZnd6d3Rzamh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4MTE2NTQsImV4cCI6MjA2NDM4NzY1NH0.HGInfGvzZDDgp6bnYGFWerqWHnDsEEzWuQVqdGGUutw",
    url: "https://wazlabkcwwjfwzwtsjhw.supabase.co",
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'L I V E',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
