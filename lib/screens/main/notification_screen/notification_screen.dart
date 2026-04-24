import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live/screens/main/controllers/friend_requests_controller.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const _purple = Color(0xFF7C56E1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => FriendRequestsController()..fetchRequests(),
      child: Scaffold(
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
        body: Consumer<FriendRequestsController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: _purple,
                  strokeWidth: 3,
                ),
              );
            }

            if (controller.requests.isEmpty) {
              return _EmptyState(isDark: isDark);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: controller.requests.length,
              itemBuilder: (context, index) => _RequestCard(
                request: controller.requests[index],
                isDark: isDark,
                controller: controller,
              ),
            );
          },
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
        Text('No pending friend requests',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            )),
      ]),
    );
  }
}
