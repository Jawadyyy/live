import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final _supabase = Supabase.instance.client;

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase.from('messages').insert({
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': false,
    });
  }

  // Get messages stream between two users - FIXED VERSION
  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Stream all messages and filter in real-time
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          // Filter messages between current user and other user
          return data.where((message) {
            final senderId = message['sender_id'];
            final receiverId = message['receiver_id'];

            return (senderId == currentUserId && receiverId == otherUserId) ||
                (senderId == otherUserId && receiverId == currentUserId);
          }).toList();
        });
  }

  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('id', messageId);
  }

  // Mark all messages from a user as read
  Future<void> markAllAsRead(String senderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('sender_id', senderId)
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').delete().eq('id', messageId);
  }

  // Get unread message count from a specific user
  Future<int> getUnreadCount(String senderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 0;

    final response = await _supabase
        .from('messages')
        .select()
        .eq('sender_id', senderId)
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);

    return response.length;
  }

  // Get last message with a user
  Future<Map<String, dynamic>?> getLastMessage(String otherUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    // Fetch messages between the two users
    final response = await _supabase
        .from('messages')
        .select()
        .order('created_at', ascending: false)
        .limit(100); // Get recent messages to filter

    // Filter manually for the conversation
    final conversation =
        response.where((message) {
          final senderId = message['sender_id'];
          final receiverId = message['receiver_id'];

          return (senderId == currentUserId && receiverId == otherUserId) ||
              (senderId == otherUserId && receiverId == currentUserId);
        }).toList();

    return conversation.isNotEmpty ? conversation.first : null;
  }
}
