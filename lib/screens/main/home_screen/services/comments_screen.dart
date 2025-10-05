import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostService {
  final _client = Supabase.instance.client;

  Future<void> addComment(String postId, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }
}

class CommentsScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;

  const CommentsScreen({super.key, required this.postId, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _postService = PostService();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      await _postService.addComment(
        widget.postId,
        _commentController.text.trim(),
      );
      _commentController.clear();
      _focusNode.unfocus();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.background : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Comments'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          SizedBox(height: 50),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _postService.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading comments',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(
                              0.3,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.comment_outlined,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No comments yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share your thoughts',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwner = currentUser?.id == comment['user_id'];

                    return FutureBuilder<Map<String, dynamic>?>(
                      future:
                          Supabase.instance.client
                              .from('users')
                              .select('username, avatar_url')
                              .eq('id', comment['user_id'])
                              .maybeSingle(),
                      builder: (context, userSnap) {
                        final user = userSnap.data ?? {};
                        final username = user['username'] ?? 'Unknown User';
                        final avatarUrl = user['avatar_url'];

                        final createdAt =
                            DateTime.tryParse(
                              comment['created_at'] ?? '',
                            )?.toLocal();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage:
                                    avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                child:
                                    avatarUrl == null
                                        ? Icon(
                                          Icons.person,
                                          size: 20,
                                          color: colorScheme.primary,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              username,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -0.2,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            createdAt != null
                                                ? timeago.format(createdAt)
                                                : '',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                          ),
                                          if (isOwner) ...[
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () async {
                                                final confirm = await showDialog<
                                                  bool
                                                >(
                                                  context: context,
                                                  builder:
                                                      (ctx) => AlertDialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        title: const Text(
                                                          'Delete Comment',
                                                        ),
                                                        content: const Text(
                                                          'Are you sure you want to delete this comment?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      false,
                                                                    ),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      true,
                                                                    ),
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor:
                                                                  colorScheme
                                                                      .error,
                                                            ),
                                                            child: const Text(
                                                              'Delete',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );

                                                if (confirm == true) {
                                                  await _postService
                                                      .deleteComment(
                                                        comment['id'],
                                                      );
                                                }
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        comment['content'],
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        maxLength: 500,
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) {
                          if (!isFocused || currentLength == 0) return null;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4, right: 12),
                            child: Text(
                              '$currentLength/$maxLength',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          );
                        },
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _isPosting ? null : _postComment,
                      icon:
                          _isPosting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
