import 'dart:math';

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

  // Generate and send OTP
  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit OTP
  }

  Future<String> sendOtp(String email) async {
    final otp = generateOtp();

    // Save to Supabase (optional – keep this if you want a backup)
    await _supabase.from('password_reset_otps').upsert({
      'email': email,
      'otp': otp,
      'expires_at':
          DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
    });

    await _supabase.auth.resetPasswordForEmail(email);

    // For testing
    print('OTP sent to $email: $otp');

    return otp;
  }

  // Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final result =
          await _supabase
              .from('password_reset_otps')
              .select()
              .eq('email', email)
              .eq('otp', otp)
              .gte('expires_at', DateTime.now().toIso8601String())
              .maybeSingle();

      // If no match or expired, maybeSingle() returns null
      return result != null;
    } catch (e) {
      print('OTP verification failed: $e');
      return false;
    }
  }

  // Reset password after OTP verification
  Future<void> resetPassword(
    String email,
    String newPassword,
    String otp,
  ) async {
    // First verify OTP
    final isValid = await verifyOtp(email, otp);
    if (!isValid) {
      throw Exception('Invalid or expired OTP');
    }

    try {
      // Update password using the new method
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Password update failed');
      }

      // Delete the used OTP
      await _supabase
          .from('password_reset_otps')
          .delete()
          .eq('email', email)
          .eq('otp', otp);
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }
}
