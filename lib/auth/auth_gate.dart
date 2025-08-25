import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/bottom_nav.dart';
import 'package:live/screens/auth/login_screen.dart';
import 'package:live/screens/main/profile_screen/profile_setup.dart';
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
          // User is authenticated, check if profile is complete
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService().fetchUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final profile = profileSnapshot.data;

              // If profile doesn't exist or is not complete, show profile setup
              if (profile == null || profile['is_profile_complete'] == false) {
                return const ProfileSetupScreen();
              }

              // Profile is complete, show main app
              return const CustomBottomNavBar();
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
