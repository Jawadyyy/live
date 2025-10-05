import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final _client = Supabase.instance.client;

  // ==================== LIKES ====================

  /// Toggle like on a post (like if not liked, unlike if already liked)
  Future<bool> toggleLike(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Check if already liked
    final existing =
        await _client
            .from('likes')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', userId)
            .maybeSingle();

    if (existing != null) {
      // Unlike
      await _client
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      return false; // unliked
    } else {
      // Like
      await _client.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true; // liked
    }
  }

  /// Get like count for a post
  Future<int> getLikeCount(String postId) async {
    final response = await _client
        .from('likes')
        .select('id')
        .eq('post_id', postId)
        .count(CountOption.exact);
    return response.count;
  }

  /// Check if current user liked a post
  Future<bool> isLikedByCurrentUser(String postId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final result =
          await _client
              .from('likes')
              .select('id')
              .eq('post_id', postId)
              .eq('user_id', userId)
              .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Stream like count for real-time updates
  Stream<int> likesCountStream(String postId) {
    return _client
        .from('likes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((data) => data.length);
  }

  // ==================== COMMENTS ====================

  /// Add a comment to a post
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

  /// Get comments for a post
  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    final response = await _client
        .from('comments')
        .select('id')
        .eq('post_id', postId)
        .count(CountOption.exact);
    return response.count;
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  /// Stream comment count for real-time updates
  Stream<int> commentsCountStream(String postId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((data) => data.length);
  }
}
