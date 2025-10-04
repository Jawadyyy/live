import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/appbar.dart';
import 'package:live/screens/main/home_screen/services/comments_screen.dart'
    show CommentsScreen;
import 'package:live/screens/main/home_screen/services/post_service.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:live/screens/main/post_screen/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  final _postService = PostService();

  Stream<List<Map<String, dynamic>>> _postsStream() {
    final client = Supabase.instance.client;
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = Supabase.instance.client.auth.currentUser;

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
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

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
                  final createdAt =
                      DateTime.tryParse(post['created_at'] ?? '')?.toLocal();
                  final updatedAt =
                      DateTime.tryParse(post['updated_at'] ?? '')?.toLocal();

                  String timeLabel;
                  if (updatedAt != null &&
                      createdAt != null &&
                      updatedAt.isAfter(createdAt)) {
                    timeLabel = "Edited • ${timeago.format(updatedAt)}";
                  } else {
                    timeLabel =
                        createdAt != null ? timeago.format(createdAt) : "";
                  }

                  final isOwner =
                      currentUser != null && currentUser.id == post['user_id'];

                  return Container(
                    key: ValueKey(post['id']),
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
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 23,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                  child:
                                      avatarUrl == null
                                          ? Icon(
                                            Icons.person,
                                            color: Colors.grey[600],
                                          )
                                          : null,
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
                                      ),
                                      if (timeLabel.isNotEmpty)
                                        Text(
                                          timeLabel,
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
                                if (isOwner)
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CreatePostScreen(
                                                  existingPost: post,
                                                ),
                                          ),
                                        ).then((_) {
                                          if (mounted) setState(() {});
                                        });
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: const Text(
                                                  "Delete Post",
                                                ),
                                                content: const Text(
                                                  "Are you sure you want to delete this post?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    child: const Text("Delete"),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirm == true) {
                                          await Supabase.instance.client
                                              .from('posts')
                                              .delete()
                                              .eq('id', post['id']);

                                          if (mounted) setState(() {});
                                        }
                                      }
                                    },
                                    itemBuilder:
                                        (context) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text("Edit"),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text("Delete"),
                                          ),
                                        ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

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

                            if (post['image_url'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  post['image_url'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Like and Comment buttons with real-time counts
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _LikeButton(
                                  postId: post['id'],
                                  postService: _postService,
                                ),
                                _CommentButton(
                                  postId: post['id'],
                                  post: post,
                                  postService: _postService,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
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
}

// Like Button Widget with real-time count
class _LikeButton extends StatelessWidget {
  final String postId;
  final PostService postService;

  const _LikeButton({required this.postId, required this.postService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: postService.isLikedByCurrentUser(postId),
      builder: (context, likedSnap) {
        final isLiked = likedSnap.data ?? false;

        return StreamBuilder<int>(
          stream: postService.likesCountStream(postId),
          builder: (context, countSnap) {
            final count = countSnap.data ?? 0;

            return TextButton.icon(
              onPressed: () async {
                try {
                  await postService.toggleLike(postId);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_outline,
                size: 20,
                color: isLiked ? Colors.red : Colors.grey[600],
              ),
              label: Text(
                count > 0 ? count.toString() : 'Like',
                style: TextStyle(
                  color: isLiked ? Colors.red : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Comment Button Widget with real-time count
class _CommentButton extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;
  final PostService postService;

  const _CommentButton({
    required this.postId,
    required this.post,
    required this.postService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: postService.commentsCountStream(postId),
      builder: (context, countSnap) {
        final count = countSnap.data ?? 0;

        return TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommentsScreen(postId: postId, post: post),
              ),
            );
          },
          icon: Icon(
            Icons.mode_comment_outlined,
            size: 20,
            color: Colors.grey[600],
          ),
          label: Text(
            count > 0 ? count.toString() : 'Comment',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        );
      },
    );
  }
}
