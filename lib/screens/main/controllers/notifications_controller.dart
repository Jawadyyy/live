import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Activity feed (likes / comments / messages / live) from the `notifications`
/// table, plus the pending-friend-request count so one badge covers both.
/// Mirrors the plain-ChangeNotifier style of friends_controller.dart.
class NotificationsController extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;

  int _unreadNotifications = 0;
  int _pendingRequests = 0;

  /// Badge number = unread activity + pending friend requests.
  int get unreadCount => _unreadNotifications + _pendingRequests;

  RealtimeChannel? _channel;

  NotificationsController() {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    // New notification rows and any friendship change re-pull, keeping the
    // badge/feed live without reopening the screen.
    _channel = supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
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

  @override
  void dispose() {
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> fetch() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

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
      _unreadNotifications =
          notifications.where((n) => n['is_read'] == false).length;

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

  /// Mark all activity read (called when the feed opens). Friend requests stay
  /// counted until acted on.
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
