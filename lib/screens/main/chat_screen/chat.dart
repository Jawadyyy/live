import 'package:flutter/material.dart';
import 'package:live/components/appbar.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:live/components/chat_fab.dart';
import 'package:live/screens/main/chat_screen/search_screen/search_screen.dart';
import 'package:live/screens/main/chat_screen/message_screen/message_screen.dart';
import 'package:live/screens/main/chat_screen/message_screen//message_service/message_service.dart';
import 'package:provider/provider.dart';
import 'package:live/screens/main/controllers/friends_controller.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ChangeNotifierProvider(
      create: (_) => FriendsController()..fetchFriends(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: const Text('Chat'),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          centerTitle: true,
          onToggleDarkMode: () async {
            final themeProvider = Provider.of<ThemeProvider>(
              context,
              listen: false,
            );
            await themeProvider.toggleTheme(!themeProvider.isDarkMode);
          },
        ),
        body: Consumer<FriendsController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.friends.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Friends Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add friends to start chatting!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            final filteredFriends =
                controller.friends.where((friend) {
                  final query = controller.searchQuery.toLowerCase();
                  final username = (friend['username'] ?? '').toLowerCase();
                  return username.contains(query);
                }).toList();

            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search friends...",
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => controller.updateSearch(value),
                  ),
                ),

                // Friends list
                Expanded(
                  child:
                      filteredFriends.isEmpty
                          ? const Center(child: Text("No results found"))
                          : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredFriends.length,
                            itemBuilder: (context, index) {
                              final friend = filteredFriends[index];
                              return _ChatListItem(friend: friend);
                            },
                          ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: const ChatFab(searchScreen: SearchScreen()),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Map<String, dynamic> friend;

  const _ChatListItem({required this.friend});

  @override
  Widget build(BuildContext context) {
    final messageService = MessageService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: messageService.getLastMessage(friend['id']),
      builder: (context, lastMessageSnapshot) {
        final lastMessage = lastMessageSnapshot.data;
        final content = lastMessage?['content'] ?? 'Tap to start chat';
        final timestamp =
            lastMessage?['created_at'] != null
                ? DateTime.parse(lastMessage!['created_at']).toLocal()
                : null;

        return FutureBuilder<int>(
          future: messageService.getUnreadCount(friend['id']),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.data ?? 0;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Stack(
                  children: [
                    Hero(
                      tag: 'avatar_${friend['id']}',
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            friend['avatar_url'] != null
                                ? NetworkImage(friend['avatar_url'])
                                : null,
                        child:
                            friend['avatar_url'] == null
                                ? const Icon(Icons.person, size: 28)
                                : null,
                      ),
                    ),
                    // Online indicator (you can implement this later)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  friend['username'] ?? "Unknown",
                  style: TextStyle(
                    fontWeight:
                        unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey[600],
                          fontWeight:
                              unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
                trailing:
                    unreadCount > 0
                        ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageScreen(friend: friend),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
