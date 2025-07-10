import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io'; // For SocketException
import 'package:flutter/services.dart'; // For PlatformException

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  Future<bool> signInWithGoogle() async {
    const webClientId =
        '608183093265-feg362p157r6k2t6elfo3aokc18h5oj4.apps.googleusercontent.com';
    const androidClientId =
        '608183093265-liidh47smc7raf166t5j9qlm21hjirad.apps.googleusercontent.com';

    final googleSignIn = GoogleSignIn(
      clientId: androidClientId,
      serverClientId: webClientId,
    );

    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false; // User cancelled

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null || accessToken == null) {
        throw Exception("Missing tokens");
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return true; // Sign-in successful
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return false;
    }
  }
}
