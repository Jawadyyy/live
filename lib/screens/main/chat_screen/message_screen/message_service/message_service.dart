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

  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          return data.where((message) {
            final senderId = message['sender_id'];
            final receiverId = message['receiver_id'];

            return (senderId == currentUserId && receiverId == otherUserId) ||
                (senderId == otherUserId && receiverId == currentUserId);
          }).toList();
        });
  }

  Future<void> markAsRead(String messageId) async {
    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('id', messageId);
  }

  Future<void> markAllAsRead(String senderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('sender_id', senderId)
        .eq('receiver_id', currentUserId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').delete().eq('id', messageId);
  }

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

  Future<Map<String, dynamic>?> getLastMessage(String otherUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    final response =
        await _supabase
            .from('messages')
            .select()
            .or('sender_id.eq.$currentUserId,sender_id.eq.$otherUserId')
            .or('receiver_id.eq.$currentUserId,receiver_id.eq.$otherUserId')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    return response;
  }
}
