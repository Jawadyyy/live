import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/appbar.dart';
import 'package:live/components/post_fab.dart';
import 'package:live/screens/main/home_screen/services/comments_screen.dart'
    show CommentsScreen;
import 'package:live/screens/main/home_screen/services/post_service.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:live/screens/main/home_screen/post_screen/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  late final AuthService _authService;
  late final PostService _postService;
  late final SupabaseClient _supabaseClient;
  Stream<List<Map<String, dynamic>>>? _postsStream;
  List<Map<String, dynamic>> _cachedPosts = [];
  bool _isLoadingFriends = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _postService = PostService();
    _supabaseClient = Supabase.instance.client;
    _initPostsStream();
  }

  Future<void> _initPostsStream() async {
    setState(() => _isLoadingFriends = true);
    final stream = await _getFriendsPosts();
    if (mounted) {
      setState(() {
        _postsStream = stream;
        _isLoadingFriends = false;
      });
    }
  }

  Future<Stream<List<Map<String, dynamic>>>> _getFriendsPosts() async {
    final currentUserId = _supabaseClient.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    try {
      final friendships = await _supabaseClient
          .from('friendships')
          .select('requester_id, addressee_id')
          .eq('status', 'accepted')
          .or('requester_id.eq.$currentUserId,addressee_id.eq.$currentUserId');

      final friendIds = friendships.map<String>((f) {
        return f['requester_id'] == currentUserId
            ? f['addressee_id'] as String
            : f['requester_id'] as String;
      }).toList();

      // Include current user's own ID so their posts appear in the feed too
      final allowedIds = [...friendIds, currentUserId];

      return _supabaseClient
          .from('posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => data
              .where((post) => allowedIds.contains(post['user_id']))
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> _openCreatePost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (result == true && mounted) {
      _initPostsStream();
    }
  }

  Future<void> _toggleTheme() async {
    final themeProvider = context.read<ThemeProvider>();
    await themeProvider.toggleTheme(!themeProvider.isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = _supabaseClient.auth.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Home'),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        centerTitle: true,
        onToggleDarkMode: _toggleTheme,
      ),
      body: _isLoadingFriends
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _cachedPosts = snapshot.data!;
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    _cachedPosts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError && _cachedPosts.isEmpty) {
                  return _ErrorState(error: snapshot.error.toString());
                }

                if (_cachedPosts.isEmpty) {
                  return const _EmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _initPostsStream,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cachedPosts.length,
                    itemBuilder: (context, index) {
                      final post = _cachedPosts[index];
                      return _PostCard(
                        key: ValueKey(post['id']),
                        post: post,
                        currentUserId: currentUser?.id,
                        isDarkMode: themeProvider.isDarkMode,
                        colorScheme: colorScheme,
                        postService: _postService,
                        onPostUpdated: () {
                          if (mounted) _initPostsStream();
                        },
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: PostFab(onPressed: _openCreatePost),
    );
  }
}

// ==================== POST CARD WIDGET ====================
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String? currentUserId;
  final bool isDarkMode;
  final ColorScheme colorScheme;
  final PostService postService;
  final VoidCallback onPostUpdated;

  const _PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.isDarkMode,
    required this.colorScheme,
    required this.postService,
    required this.onPostUpdated,
  });

  bool get isOwner => currentUserId != null && currentUserId == post['user_id'];

  String _getTimeLabel(DateTime? createdAt, DateTime? updatedAt) {
    if (updatedAt != null &&
        createdAt != null &&
        updatedAt.isAfter(createdAt)) {
      return "Edited • ${timeago.format(updatedAt)}";
    }
    return createdAt != null ? timeago.format(createdAt) : "";
  }

  Future<void> _handleEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(existingPost: post)),
    );
    if (result == true) onPostUpdated();
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('posts')
            .delete()
            .eq('id', post['id']);
        onPostUpdated();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete post: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
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
        final timeLabel = _getTimeLabel(createdAt, updatedAt);

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: isDarkMode ? colorScheme.surface : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostHeader(
                    username: username,
                    avatarUrl: avatarUrl,
                    timeLabel: timeLabel,
                    isOwner: isOwner,
                    onEdit: () => _handleEdit(context),
                    onDelete: () => _handleDelete(context),
                  ),
                  const SizedBox(height: 16),
                  if (post['content'] != null &&
                      post['content'].toString().isNotEmpty)
                    _PostContent(content: post['content']),
                  if (post['image_url'] != null)
                    _PostImage(imageUrl: post['image_url']),
                  const SizedBox(height: 12),
                  _PostActions(
                    postId: post['id'],
                    post: post,
                    postService: postService,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==================== POST HEADER ====================
class _PostHeader extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String timeLabel;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PostHeader({
    required this.username,
    required this.avatarUrl,
    required this.timeLabel,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: Colors.grey[200],
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(Icons.person, color: Colors.grey[600])
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
              ),
              if (timeLabel.isNotEmpty)
                Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                ),
            ],
          ),
        ),
        if (isOwner)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text("Edit")),
              PopupMenuItem(value: 'delete', child: Text("Delete")),
            ],
          ),
      ],
    );
  }
}

// ==================== POST CONTENT ====================
class _PostContent extends StatelessWidget {
  final String content;
  const _PostContent({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        content,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontSize: 15, height: 1.4),
      ),
    );
  }
}

// ==================== POST IMAGE ====================
class _PostImage extends StatelessWidget {
  final String imageUrl;
  const _PostImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}

// ==================== POST ACTIONS ====================
class _PostActions extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;
  final PostService postService;

  const _PostActions({
    required this.postId,
    required this.post,
    required this.postService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _LikeButton(postId: postId, postService: postService),
        _CommentButton(postId: postId, post: post, postService: postService),
      ],
    );
  }
}

// ==================== LIKE BUTTON ====================
class _LikeButton extends StatefulWidget {
  final String postId;
  final PostService postService;

  const _LikeButton({required this.postId, required this.postService});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _isLiked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animationController);
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    try {
      final isLiked =
          await widget.postService.isLikedByCurrentUser(widget.postId);
      if (mounted)
        setState(() {
          _isLiked = isLiked;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLike() async {
    final previousState = _isLiked;
    try {
      setState(() => _isLiked = !_isLiked);
      if (_isLiked) _animationController.forward(from: 0);
      final newLikeState = await widget.postService.toggleLike(widget.postId);
      if (mounted) setState(() => _isLiked = newLikeState);
    } catch (e) {
      if (mounted) {
        setState(() => _isLiked = previousState);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return TextButton.icon(
        onPressed: null,
        icon: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
        label: Text('Like',
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      );
    }

    return StreamBuilder<int>(
      stream: widget.postService.likesCountStream(widget.postId),
      builder: (context, countSnap) {
        final count = countSnap.data ?? 0;
        return TextButton.icon(
          onPressed: _handleLike,
          icon: ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_outline,
              size: 20,
              color: _isLiked ? Colors.red : Colors.grey[600],
            ),
          ),
          label: Text(
            count > 0 ? count.toString() : 'Like',
            style: TextStyle(
              color: _isLiked ? Colors.red : Colors.grey[600],
              fontSize: 12,
              fontWeight: _isLiked ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }
}

// ==================== COMMENT BUTTON ====================
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
          icon: Icon(Icons.mode_comment_outlined,
              size: 20, color: Colors.grey[600]),
          label: Text(
            count > 0 ? count.toString() : 'Comment',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        );
      },
    );
  }
}

// ==================== EMPTY STATE ====================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No posts yet",
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text("Add friends to see their posts here!",
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ==================== ERROR STATE ====================
class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text("Something went wrong",
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
