import 'package:flutter/material.dart';
import 'package:live/components/bottom_nav.dart';
import 'package:live/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: (Center(child: CircularProgressIndicator())),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return const CustomBottomNavBar();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
