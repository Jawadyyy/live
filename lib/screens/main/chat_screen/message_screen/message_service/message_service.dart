import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class MessageService {
  final _supabase = Supabase.instance.client;
  static const _storageBucket = 'chat-attachments';

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

  Future<Map<String, dynamic>> uploadFile(
      {required File file, required String receiverId}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');
    final fileName = p.basename(file.path);
    final fileExt = p.extension(file.path).toLowerCase();
    final fileSize = await file.length();
    final storagePath =
        '$currentUserId/$receiverId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage.from(_storageBucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(contentType: _getMimeType(fileExt)),
        );
    final isImage =
        ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(fileExt);
    return {
      'file_url':
          _supabase.storage.from(_storageBucket).getPublicUrl(storagePath),
      'file_name': fileName,
      'file_size': fileSize,
      'message_type': isImage ? 'image' : 'file',
    };
  }

  Future<void> sendFileMessage(
      {required String receiverId, required File file, String? caption}) async {
    final r = await uploadFile(file: file, receiverId: receiverId);
    await sendMessage(
      receiverId: receiverId,
      content: caption ?? '',
      messageType: r['message_type'],
      fileUrl: r['file_url'],
      fileName: r['file_name'],
      fileSize: r['file_size'],
    );
  }

  String _getMimeType(String ext) {
    switch (ext) {
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

  // Used by MessageScreen — streams full conversation
  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data.where((m) {
              final s = m['sender_id'], r = m['receiver_id'];
              return (s == currentUserId && r == otherUserId) ||
                  (s == otherUserId && r == currentUserId);
            }).toList());
  }

  // Used by ChatScreen list items — streams just the last message
  Stream<Map<String, dynamic>?> getLastMessageStream(String otherUserId) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value(null);
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          final conv = data.where((m) {
            final s = m['sender_id'], r = m['receiver_id'];
            return (s == currentUserId && r == otherUserId) ||
                (s == otherUserId && r == currentUserId);
          }).toList();
          return conv.isNotEmpty ? conv.first : null;
        });
  }

  Future<void> markAsRead(String messageId) async {
    await _supabase
        .from('messages')
        .update({'is_read': true}).eq('id', messageId);
  }

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

  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').delete().eq('id', messageId);
  }

  // Kept for any legacy usage
  Future<int> getUnreadCount(String senderId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 0;
    final r = await _supabase
        .from('messages')
        .select()
        .eq('sender_id', senderId)
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);
    return r.length;
  }

  Future<Map<String, dynamic>?> getLastMessage(String otherUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;
    final r = await _supabase
        .from('messages')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    final conv = r.where((m) {
      final s = m['sender_id'], rv = m['receiver_id'];
      return (s == currentUserId && rv == otherUserId) ||
          (s == otherUserId && rv == currentUserId);
    }).toList();
    return conv.isNotEmpty ? conv.first : null;
  }
}
