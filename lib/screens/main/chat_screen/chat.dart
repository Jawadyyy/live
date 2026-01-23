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
                // Enhanced Search bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search friends...",
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) => controller.updateSearch(value),
                    ),
                  ),
                ),

                // Friends list with improved spacing
                Expanded(
                  child:
                      filteredFriends.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No results found",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Try a different search term",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>?>(
      future: messageService.getLastMessage(friend['id']),
      builder: (context, lastMessageSnapshot) {
        final lastMessage = lastMessageSnapshot.data;
        final content = lastMessage?['content'] ?? 'Tap to start chat';
        final isNewChat = lastMessage == null;
        final timestamp =
            lastMessage?['created_at'] != null
                ? DateTime.parse(lastMessage!['created_at']).toLocal()
                : null;

        return FutureBuilder<int>(
          future: messageService.getUnreadCount(friend['id']),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.data ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageScreen(friend: friend),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          unreadCount > 0
                              ? Border.all(
                                color: theme.primaryColor.withOpacity(0.3),
                                width: 1.5,
                              )
                              : Border.all(color: Colors.transparent),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.1 : 0.05,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar with online indicator
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            // Avatar background glow for unread messages
                            if (unreadCount > 0)
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.primaryColor.withOpacity(0.1),
                                ),
                              ),

                            // Avatar
                            Hero(
                              tag: 'avatar_${friend['id']}',
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.cardColor,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundImage:
                                      friend['avatar_url'] != null
                                          ? NetworkImage(friend['avatar_url'])
                                          : null,
                                  backgroundColor: theme.primaryColor
                                      .withOpacity(0.1),
                                  child:
                                      friend['avatar_url'] == null
                                          ? Icon(
                                            Icons.person_rounded,
                                            size: 28,
                                            color: theme.primaryColor,
                                          )
                                          : null,
                                ),
                              ),
                            ),

                            // Online indicator
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.cardColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // Message content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      friend['username'] ?? "Unknown",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            unreadCount > 0
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (timestamp != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      timeago.format(timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.hintColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color:
                                            isNewChat
                                                ? theme.primaryColor
                                                : theme.hintColor,
                                        fontWeight:
                                            unreadCount > 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                        fontStyle:
                                            isNewChat
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                      ),
                                    ),
                                  ),

                                  if (unreadCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        unreadCount > 9
                                            ? '9+'
                                            : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Chevron icon
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: theme.hintColor.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
