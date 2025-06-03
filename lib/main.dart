import 'package:flutter/material.dart';
import 'package:live/auth/auth_gate.dart';
import 'package:live/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  //supabase setup
  await Supabase.initialize(
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhemxhYmtjd3dqZnd6d3Rzamh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4MTE2NTQsImV4cCI6MjA2NDM4NzY1NH0.HGInfGvzZDDgp6bnYGFWerqWHnDsEEzWuQVqdGGUutw",
    url: "https://wazlabkcwwjfwzwtsjhw.supabase.co",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(),
    );
  }
}
