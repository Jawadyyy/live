import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live/screens/main/controllers/friend_requests_controller.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => FriendRequestsController()..fetchRequests(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Friend Requests"), centerTitle: true),
        body: Consumer<FriendRequestsController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.requests.isEmpty) {
              return const Center(child: Text("No pending requests"));
            }

            return ListView.builder(
              itemCount: controller.requests.length,
              itemBuilder: (context, index) {
                final request = controller.requests[index];
                final user = request['users'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user['avatar_url'] != null
                              ? NetworkImage(user['avatar_url'])
                              : null,
                      child:
                          user['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(user['username'] ?? "Unknown"),
                    subtitle: const Text("sent you a friend request"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed:
                              () => controller.respondToRequest(
                                request['id'],
                                'accepted',
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed:
                              () => controller.respondToRequest(
                                request['id'],
                                'rejected',
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
