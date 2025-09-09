import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/appbar.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live/components/post_fab.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();

  /// A stream that listens for realtime changes on `posts`
  Stream<List<Map<String, dynamic>>> _postsStream() {
    final client = Supabase.instance.client;

    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Home'),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        centerTitle: true,
        onToggleDarkMode: () async {
          final themeProvider = Provider.of<ThemeProvider>(
            context,
            listen: false,
          );
          await themeProvider.toggleTheme(!themeProvider.isDarkMode);
        },
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No posts yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Be the first to share something!",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              // Fetch user info separately
              return FutureBuilder(
                future:
                    Supabase.instance.client
                        .from('users')
                        .select('username, avatar_url')
                        .eq('id', post['user_id'])
                        .maybeSingle(),
                builder: (context, userSnap) {
                  final user = userSnap.data ?? {};
                  final username = user['username'] ?? "Unknown";
                  final avatarUrl = user['avatar_url'];
                  final createdAt = DateTime.tryParse(post['created_at'] ?? '');
                  final timeAgo =
                      createdAt != null ? timeago.format(createdAt) : "";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: isDarkMode ? colorScheme.surface : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Info Row
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.primary.withOpacity(
                                        0.2,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        avatarUrl != null
                                            ? NetworkImage(avatarUrl)
                                            : null,
                                    child:
                                        avatarUrl == null
                                            ? Icon(
                                              Icons.person,
                                              size: 22,
                                              color: Colors.grey[600],
                                            )
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (timeAgo.isNotEmpty)
                                        Text(
                                          timeAgo,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Colors.grey[500],
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Post Content
                            if (post['content'] != null &&
                                post['content'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  post['content'],
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontSize: 15, height: 1.4),
                                ),
                              ),

                            // Post Image
                            if (post['image_url'] != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    post['image_url'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(Icons.error),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            // Action Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildActionButton(
                                  icon: Icons.favorite_outline,
                                  label: 'Like',
                                  onPressed: () {},
                                  color: Colors.grey[600],
                                ),
                                _buildActionButton(
                                  icon: Icons.mode_comment_outlined,
                                  label: 'Comment',
                                  onPressed: () {},
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: const PostFab(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
