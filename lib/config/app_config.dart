/// Central place for all client-side service identifiers.
///
/// NOTE: Everything in this file ships inside the app binary and is
/// considered PUBLIC by design (Supabase anon key, Agora app ID, Google
/// OAuth *client IDs*). None of these are secrets — actual security comes
/// from Supabase Row Level Security policies and the Agora token server.
///
/// Never put service-role keys, Agora app certificates, or OAuth client
/// *secrets* here or anywhere else in the app.
class AppConfig {
  AppConfig._();

  // ── Supabase ──────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://wazlabkcwwjfwzwtsjhw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhemxhYmtjd3dqZnd6d3Rzamh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4MTE2NTQsImV4cCI6MjA2NDM4NzY1NH0.HGInfGvzZDDgp6bnYGFWerqWHnDsEEzWuQVqdGGUutw';

  // ── Agora ─────────────────────────────────────────────────────────────
  static const String agoraAppId = '3438fb4f909e4753b9f88291f2b22929';

  // ── Google Sign-In (client IDs, not secrets) ──────────────────────────
  static const String googleWebClientId =
      '608183093265-feg362p157r6k2t6elfo3aokc18h5oj4.apps.googleusercontent.com';
  static const String googleAndroidClientId =
      '608183093265-liidh47smc7raf166t5j9qlm21hjirad.apps.googleusercontent.com';
}
