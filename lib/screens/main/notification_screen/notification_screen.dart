import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:live/screens/main/controllers/friend_requests_controller.dart';
import 'package:live/screens/main/controllers/notifications_controller.dart';
import 'package:live/screens/main/chat_screen/message_screen/message_screen.dart';
import 'package:live/screens/main/stream_screen/watch_stream_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _purple = Color(0xFF7C56E1);

  final _reqs = FriendRequestsController();
  final _notifs = NotificationsController();

  @override
  void initState() {
    super.initState();
    _reqs.fetchRequests();
    // Mark activity read once it's loaded (opening the screen clears the badge).
    _notifs.fetch().then((_) => _notifs.markAllRead());
  }

  @override
  void dispose() {
    _reqs.dispose();
    _notifs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_reqs, _notifs]),
        builder: (context, _) {
          if (_reqs.isLoading && _notifs.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _purple, strokeWidth: 3),
            );
          }

          final requests = _reqs.requests;
          final activity = _notifs.notifications;

          if (requests.isEmpty && activity.isEmpty) {
            return _EmptyState(isDark: isDark);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              for (final r in requests)
                _RequestCard(request: r, isDark: isDark, controller: _reqs),
              for (final n in activity)
                _ActivityTile(notification: n, isDark: isDark),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isDark;

  const _ActivityTile({required this.notification, required this.isDark});

  static const _purple = Color(0xFF7C56E1);

  String get _actionText {
    switch (notification['type']) {
      case 'like':
        return ' liked your post';
      case 'comment':
        return ' commented on your post';
      case 'message':
        return ' sent you a message';
      case 'live':
        return ' is live now';
      default:
        return '';
    }
  }

  IconData get _icon {
    switch (notification['type']) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.mode_comment_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'live':
        return Icons.sensors_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Future<void> _onTap(BuildContext context) async {
    final actor = notification['actor'] as Map<String, dynamic>? ?? {};
    final type = notification['type'];
    final entityId = notification['entity_id'] as String?;

    if (type == 'message') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessageScreen(friend: {
            'id': actor['id'],
            'username': actor['username'],
            'avatar_url': actor['avatar_url'],
          }),
        ),
      );
    } else if (type == 'live' && entityId != null) {
      try {
        final stream = await Supabase.instance.client
            .from('streams')
            .select()
            .eq('id', entityId)
            .maybeSingle();
        if (!context.mounted) return;
        if (stream != null && stream['status'] == 'live') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WatchStreamScreen(streamData: stream),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stream has ended')),
          );
        }
      } catch (_) {}
    }
    // like/comment have no post-detail screen to route to — no-op.
  }

  @override
  Widget build(BuildContext context) {
    final actor = notification['actor'] as Map<String, dynamic>? ?? {};
    final username = actor['username'] ?? 'Someone';
    final avatarUrl = actor['avatar_url'] as String?;
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '');

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : _purple.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Avatar with type-icon badge
            Stack(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _purple.withOpacity(0.15),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(username[0].toUpperCase(),
                        style: const TextStyle(
                          color: _purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ))
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _purple,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(_icon, size: 10, color: Colors.white),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                            text: username,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: _actionText),
                      ],
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isDark;
  final FriendRequestsController controller;

  const _RequestCard({
    required this.request,
    required this.isDark,
    required this.controller,
  });

  static const _purple = Color(0xFF7C56E1);

  @override
  Widget build(BuildContext context) {
    final user = request['users'] ?? {};
    final username = user['username'] ?? 'Unknown';
    final avatarUrl = user['avatar_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : _purple.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7C56E1), Color(0xFFA37BFF)],
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(username[0].toUpperCase(),
                      style: const TextStyle(
                        color: _purple,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ))
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Text
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                        text: username,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' sent you a friend request'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                // Accept
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.respondToRequest(request['id'], 'accepted'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C56E1), Color(0xFFA37BFF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Accept',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Decline
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.respondToRequest(request['id'], 'rejected'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded,
                              size: 16, color: Colors.red),
                          SizedBox(width: 4),
                          Text('Decline',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7C56E1).withOpacity(0.1),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 44, color: Color(0xFF7C56E1)),
        ),
        const SizedBox(height: 20),
        Text('All caught up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            )),
        const SizedBox(height: 8),
        Text('Nothing new right now',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            )),
      ]),
    );
  }
}
