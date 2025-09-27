import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/appbar.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:live/components/chat_fab.dart';
import 'package:live/screens/main/chat_screen/search_screen/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:live/screens/main/controllers/friends_controller.dart';

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
              return const Center(child: Text("No friends yet"));
            }
            final filteredFriends =
                controller.friends.where((friend) {
                  final query = controller.searchQuery.toLowerCase();
                  final username = (friend['username'] ?? '').toLowerCase();
                  return username.contains(query);
                }).toList();

            return Column(
              children: [
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
                Expanded(
                  child:
                      filteredFriends.isEmpty
                          ? const Center(child: Text("No results found"))
                          : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredFriends.length,
                            itemBuilder: (context, index) {
                              final friend = filteredFriends[index];
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
                                  leading: CircleAvatar(
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
                                  title: Text(
                                    friend['username'] ?? "Unknown",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Tap to start chat",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  onTap: () {},
                                ),
                              );
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
