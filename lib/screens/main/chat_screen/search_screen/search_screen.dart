import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live/screens/main/chat_screen/search_screen/controller/search_controller.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => FriendSearchController(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Search"), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<FriendSearchController>(
            builder: (context, controller, _) {
              return Column(
                children: [
                  TextField(
                    controller: controller.textController,
                    onChanged: controller.searchUsers,
                    decoration: InputDecoration(
                      hintText: "Search by username...",
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (controller.isLoading) const CircularProgressIndicator(),
                  if (!controller.isLoading && controller.results.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.results.length,
                        itemBuilder: (context, index) {
                          final user = controller.results[index];
                          return ListTile(
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
                            title: Text(user['username']),
                            subtitle: Text(user['bio'] ?? ""),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.person_add_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () {
                                controller.sendFriendRequest(user['id']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Friend request sent to ${user['username']}",
                                    ),
                                  ),
                                );
                              },
                            ),
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
