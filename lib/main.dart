import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:live/config/app_config.dart';
import 'package:live/screens/intro/splash_screen.dart';
import 'package:live/screens/theme/app_theme.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:live/services/push_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase setup
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Firebase / push. Guarded so the app still runs if Firebase isn't
  // configured yet (e.g. missing google-services.json on a dev build).
  try {
    await Firebase.initializeApp();
    await PushService.init();
  } catch (e) {
    debugPrint('Push init skipped: $e');
  }

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
