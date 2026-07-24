import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Activity feed (likes / comments / messages / live) from the `notifications`
/// table, plus the pending-friend-request count so one badge covers both.
///
/// Singleton: the app shows the bell badge on 4 IndexedStack tabs at once, so a
/// per-widget instance would create 4 realtime channels with the same topic
/// (they collide and realtime stops firing). One shared instance = one channel,
/// one source of truth, so every badge + the screen stay in sync live.
class NotificationsController extends ChangeNotifier {
  NotificationsController._internal() {
    _subscribe();
    fetch();
  }

  static final NotificationsController instance =
      NotificationsController._internal();

  factory NotificationsController() => instance;

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;

  int _unreadNotifications = 0;
  int _pendingRequests = 0;

  /// Badge number = unread activity + pending friend requests.
  int get unreadCount => _unreadNotifications + _pendingRequests;

  RealtimeChannel? _channel;

  void _subscribe() {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    // New/changed notification rows and any friendship change re-pull, keeping
    // the badge/feed live without reopening the screen.
    _channel = supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: uid,
          ),
          callback: (_) => fetch(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          callback: (_) => fetch(),
        )
        .subscribe();
  }

  // ponytail: singleton keeps the channel for the app's life; nothing disposes
  // it. Add a reset() tied to auth changes if account-switching ships.

  void _recount() {
    _unreadNotifications =
        notifications.where((n) => n['is_read'] == false).length;
  }

  Future<void> fetch() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    // Channel may have been skipped if built pre-login; attach now.
    if (_channel == null) _subscribe();

    isLoading = true;
    notifyListeners();

    try {
      final rows = await supabase
          .from('notifications')
          .select(
            'id, type, entity_id, created_at, is_read, '
            'actor:users!notifications_actor_id_fkey(id, username, avatar_url)',
          )
          .eq('recipient_id', uid)
          .order('created_at', ascending: false)
          .limit(50);

      notifications = List<Map<String, dynamic>>.from(rows);
      _recount();

      final pending = await supabase
          .from('friendships')
          .select('id')
          .eq('addressee_id', uid)
          .eq('status', 'pending')
          .count(CountOption.exact);
      _pendingRequests = pending.count;
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Flip a single notification's read state (tap = read, long-press = unread).
  Future<void> setRead(String id, bool read) async {
    final n = notifications.firstWhere(
      (n) => n['id'] == id,
      orElse: () => {},
    );
    if (n.isEmpty || n['is_read'] == read) return;

    n['is_read'] = read;
    _recount();
    notifyListeners();

    try {
      await supabase
          .from('notifications')
          .update({'is_read': read}).eq('id', id);
    } catch (e) {
      debugPrint('❌ Error updating notification: $e');
    }
  }

  /// Mark all activity read. Friend requests stay counted until acted on.
  Future<void> markAllRead() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null || _unreadNotifications == 0) return;

    _unreadNotifications = 0;
    for (final n in notifications) {
      n['is_read'] = true;
    }
    notifyListeners();

    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', uid)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('❌ Error marking notifications read: $e');
    }
  }
}
