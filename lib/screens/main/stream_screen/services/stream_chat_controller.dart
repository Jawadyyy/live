import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live-stream chat + ephemeral events for one stream.
///
/// - Messages: reactive `stream_messages` rows (insert/delete reflected live).
/// - Reactions & join toasts: Supabase realtime *broadcast* — never stored.
/// - `canChat`: host or an accepted friend of the host (friends-only gate;
///   RLS enforces it server-side, this just drives the input UI).
class StreamChatController extends ChangeNotifier {
  StreamChatController({required this.streamId, required this.hostId}) {
    _init();
  }

  final String streamId;
  final String hostId;
  final _supabase = Supabase.instance.client;

  /// Persisted chat rows, oldest→newest.
  List<Map<String, dynamic>> messages = [];

  /// Ephemeral 'X joined' lines, merged into the feed at render time.
  final List<Map<String, dynamic>> _system = [];

  /// username/avatar_url keyed by user id, filled lazily as messages arrive.
  final Map<String, Map<String, dynamic>> _users = {};

  bool canChat = false;
  String? _myUsername;

  StreamSubscription? _msgSub;
  RealtimeChannel? _events;

  /// Floating-reaction emojis for the animation layer to consume.
  final _reactions = StreamController<String>.broadcast();
  Stream<String> get reactions => _reactions.stream;

  /// Messages + system lines, chronologically merged.
  List<Map<String, dynamic>> get feed {
    final all = [...messages, ..._system];
    all.sort((a, b) =>
        (a['created_at'] as String).compareTo(b['created_at'] as String));
    return all;
  }

  Map<String, dynamic> userFor(String id) => _users[id] ?? const {};

  Future<void> _init() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    // Who am I + may I chat here?
    try {
      final me = await _supabase
          .from('users')
          .select('username')
          .eq('id', uid)
          .maybeSingle();
      _myUsername = me?['username'] as String?;
      _users[uid] = {'username': _myUsername, 'avatar_url': null};
    } catch (_) {}
    canChat = uid == hostId || await _isFriendOfHost(uid);
    notifyListeners();

    _subscribeMessages();
    _subscribeEvents();
  }

  Future<bool> _isFriendOfHost(String uid) async {
    if (uid == hostId) return true;
    try {
      final rows = await _supabase
          .from('friendships')
          .select('id')
          .eq('status', 'accepted')
          .or('and(requester_id.eq.$uid,addressee_id.eq.$hostId),'
              'and(requester_id.eq.$hostId,addressee_id.eq.$uid)')
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _subscribeMessages() {
    _msgSub = _supabase
        .from('stream_messages')
        .stream(primaryKey: ['id'])
        .eq('stream_id', streamId)
        .order('created_at')
        .limit(100)
        .listen((rows) async {
          messages = List<Map<String, dynamic>>.from(rows);
          await _hydrateUsers();
          notifyListeners();
        });
  }

  /// Fetch username/avatar for any senders we haven't cached yet.
  Future<void> _hydrateUsers() async {
    final missing = messages
        .map((m) => m['user_id'] as String)
        .where((id) => !_users.containsKey(id))
        .toSet()
        .toList();
    if (missing.isEmpty) return;
    try {
      final rows = await _supabase
          .from('users')
          .select('id, username, avatar_url')
          .inFilter('id', missing);
      for (final u in rows) {
        _users[u['id'] as String] = u;
      }
    } catch (_) {}
  }

  void _subscribeEvents() {
    _events = _supabase.channel('stream:$streamId')
      ..onBroadcast(
        event: 'reaction',
        callback: (payload) {
          final emoji = payload['emoji'] as String?;
          if (emoji != null) _reactions.add(emoji);
        },
      )
      ..onBroadcast(
        event: 'join',
        callback: (payload) {
          final name = payload['username'] as String? ?? 'Someone';
          _system.add({
            'type': 'system',
            'text': '$name joined',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'id': 'sys-${DateTime.now().microsecondsSinceEpoch}',
          });
          // Keep the ephemeral list from growing unbounded.
          if (_system.length > 20) _system.removeRange(0, _system.length - 20);
          notifyListeners();
        },
      )
      ..subscribe((status, _) {
        // Announce myself once the channel is live.
        if (status == RealtimeSubscribeStatus.subscribed &&
            _myUsername != null) {
          _events?.sendBroadcastMessage(
            event: 'join',
            payload: {'username': _myUsername},
          );
        }
      });
  }

  Future<void> send(String text) async {
    final content = text.trim();
    final uid = _supabase.auth.currentUser?.id;
    if (content.isEmpty || uid == null) return;
    try {
      await _supabase.from('stream_messages').insert({
        'stream_id': streamId,
        'user_id': uid,
        'content': content,
      });
    } catch (e) {
      debugPrint('❌ stream chat send failed: $e');
    }
  }

  Future<void> delete(String messageId) async {
    try {
      await _supabase.from('stream_messages').delete().eq('id', messageId);
    } catch (e) {
      debugPrint('❌ stream chat delete failed: $e');
    }
  }

  /// Can the current user remove this message (own message or the host)?
  bool canDelete(Map<String, dynamic> message) {
    final uid = _supabase.auth.currentUser?.id;
    return uid != null && (message['user_id'] == uid || uid == hostId);
  }

  void sendReaction(String emoji) {
    _reactions.add(emoji); // show locally without waiting for round-trip
    _events?.sendBroadcastMessage(event: 'reaction', payload: {'emoji': emoji});
  }

  /// Stable per-user color, Twitch-style.
  static Color colorFor(String name) {
    final hue = (name.hashCode & 0xFFFFFF) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.68).toColor();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    if (_events != null) _supabase.removeChannel(_events!);
    _reactions.close();
    super.dispose();
  }
}
