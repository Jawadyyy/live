import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class MessageService {
  final _supabase = Supabase.instance.client;
  static const _storageBucket = 'chat-attachments';

  // Send a text message
  Future<void> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase.from('messages').insert({
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': false,
      'message_type': messageType,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
    });
  }

  // Upload a file to Supabase Storage and return the public URL
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String receiverId,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final fileName = p.basename(file.path);
    final fileExt = p.extension(file.path).toLowerCase();
    final fileSize = await file.length();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Create a unique path: senderId/receiverId/timestamp_filename
    final storagePath = '$currentUserId/$receiverId/${timestamp}_$fileName';

    // Upload to Supabase Storage
    await _supabase.storage.from(_storageBucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: _getMimeType(fileExt),
          ),
        );

    // Get the public URL
    final publicUrl =
        _supabase.storage.from(_storageBucket).getPublicUrl(storagePath);

    // Determine message type from extension
    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
        .contains(fileExt);

    return {
      'file_url': publicUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'message_type': isImage ? 'image' : 'file',
    };
  }

  // Send a file message (upload + send in one call)
  Future<void> sendFileMessage({
    required String receiverId,
    required File file,
    String? caption,
  }) async {
    final uploadResult = await uploadFile(file: file, receiverId: receiverId);

    await sendMessage(
      receiverId: receiverId,
      content: caption ?? '',
      messageType: uploadResult['message_type'],
      fileUrl: uploadResult['file_url'],
      fileName: uploadResult['file_name'],
      fileSize: uploadResult['file_size'],
    );
  }

  // Get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.zip':
        return 'application/zip';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // Get messages stream between two users
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
