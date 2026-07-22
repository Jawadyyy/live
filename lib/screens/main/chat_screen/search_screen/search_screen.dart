import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live/screens/main/chat_screen/search_screen/controller/search_controller.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => FriendSearchController(),
      child: Scaffold(
        backgroundColor: cs.background,
        appBar: AppBar(title: const Text("Find Friends"), centerTitle: true),
        body: Consumer<FriendSearchController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                // ── Search box on a distinct surface ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: controller.textController,
                      onChanged: controller.searchUsers,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: "Search by username...",
                        prefixIcon: Icon(Icons.search, color: cs.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ),

                // ── Results / states ──────────────────────────────────────
                Expanded(
                  child: _buildBody(context, controller, cs),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FriendSearchController controller,
    ColorScheme cs,
  ) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.textController.text.isEmpty) {
      return _EmptyState(
        cs: cs,
        icon: Icons.person_search_rounded,
        title: 'Find your friends',
        subtitle: 'Search by username to send a friend request.',
      );
    }

    if (controller.results.isEmpty) {
      return _EmptyState(
        cs: cs,
        icon: Icons.search_off_rounded,
        title: 'No users found',
        subtitle: 'Try a different username.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: controller.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = controller.results[index];
        return _ResultCard(user: user, cs: cs, controller: controller);
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final ColorScheme cs;
  final FriendSearchController controller;

  const _ResultCard({
    required this.user,
    required this.cs,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username'] ?? '?';
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cs.primary.withOpacity(0.15),
            backgroundImage: user['avatar_url'] != null
                ? NetworkImage(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? Text(
                    username.toString().isNotEmpty
                        ? username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if ((user['bio'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user['bio'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              controller.sendFriendRequest(user['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Friend request sent to $username")),
              );
            },
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.cs,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.1),
              ),
              child: Icon(icon, size: 44, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
