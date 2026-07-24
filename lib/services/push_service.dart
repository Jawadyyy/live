import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM device-token registration. Sends live in an edge function (`send-push`)
/// triggered by DB webhooks — this side only keeps `device_tokens` current so
/// the server knows where to deliver.
///
/// Notification-payload pushes are shown by the OS automatically when the app
/// is backgrounded/closed, so there's no foreground-display code here (add
/// flutter_local_notifications later if in-app banners are wanted).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // No-op: OS renders notification payloads. Hook here for data-only messages.
}

class PushService {
  static final _fm = FirebaseMessaging.instance;
  static final _sb = Supabase.instance.client;

  /// Call once after Firebase.initializeApp(). Safe to call before login —
  /// the token is (re)saved whenever a session becomes available.
  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await _fm.requestPermission();
    await _saveToken();
    _fm.onTokenRefresh.listen(_upsert);
    _sb.auth.onAuthStateChange.listen((state) {
      if (state.session != null) _saveToken();
    });
  }

  static Future<void> _saveToken() async {
    final token = await _fm.getToken();
    if (token != null) await _upsert(token);
  }

  static Future<void> _upsert(String token) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    await _sb.from('device_tokens').upsert({
      'user_id': uid,
      'token': token,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Call before signing out so this device stops receiving the ex-user's
  /// pushes (FCM tokens are per-install, not per-user).
  static Future<void> removeToken() async {
    final uid = _sb.auth.currentUser?.id;
    final token = await _fm.getToken();
    if (uid == null || token == null) return;
    await _sb
        .from('device_tokens')
        .delete()
        .eq('user_id', uid)
        .eq('token', token);
  }
}
