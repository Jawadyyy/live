/// ─────────────────────────────────────────────
///  Agora Configuration
///  Paste your Agora App ID below.
///  Get it from: https://console.agora.io
/// ─────────────────────────────────────────────
class AgoraConfig {
  // ✅ Paste your Agora App ID here
  static const String appId = '3438fb4f909e4753b9f88291f2b22929';

  // ─── Token ────────────────────────────────────
  // For TESTING: generate a temp token at https://console.agora.io
  //              → your project → "Temp Token Generator"
  // For PRODUCTION: leave this null and use a token server instead.
  //
  // If you selected "Testing mode (App ID only)" in the Agora console,
  // set this to null AND set useToken = false.
  static const String? tempToken = null; // e.g. '007eJx...'

  /// Set to false if your Agora project is in "Testing mode (App ID only)"
  static const bool useToken = false;

  // ─── Call Settings ────────────────────────────
  /// Default video resolution sent to remote peers
  static const int videoWidth = 640;
  static const int videoHeight = 480;
  static const int videoFrameRate = 15;

  /// Agora SDK log level (0=debug, 1=info, 2=warn, 3=error, 8=off)
  static const int logLevel = 1;
}
