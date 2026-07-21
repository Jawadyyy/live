import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// App-wide online presence via a single Supabase Realtime presence channel.
///
/// Each signed-in client `track`s its own user id on one shared channel; the
/// synced presence state is the set of currently-online user ids. No DB column
/// or heartbeat needed — presence is dropped automatically when a client
/// disconnects. Read [online] anywhere to reflect who is online right now.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  /// User ids currently online (includes self).
  final ValueNotifier<Set<String>> online = ValueNotifier<Set<String>>({});

  bool isOnline(String? id) => id != null && online.value.contains(id);

  /// Start tracking self and listening for others. Safe to call more than once.
  void start() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null || _channel != null) return;

    final channel = _supabase.channel('online-users');

    channel.onPresenceSync((_) {
      final ids = <String>{};
      for (final state in channel.presenceState()) {
        for (final presence in state.presences) {
          final uid = presence.payload['user_id'];
          if (uid is String) ids.add(uid);
        }
      }
      online.value = ids;
    });

    channel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.track({'user_id': myId});
      }
    });

    _channel = channel;
  }

  Future<void> stop() async {
    online.value = {};
    final ch = _channel;
    _channel = null;
    if (ch != null) await _supabase.removeChannel(ch);
  }
}
