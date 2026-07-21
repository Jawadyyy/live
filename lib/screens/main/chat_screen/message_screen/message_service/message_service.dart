import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class MessageService {
  final _supabase = Supabase.instance.client;
  static const _storageBucket = 'chat-attachments';

  /// How long a signed media URL stays valid (seconds).
  static const _signedUrlTtl = 60 * 60; // 1 hour

  /// Marker that appears in the OLD-style public URLs we used to store, e.g.
  /// https://<proj>.supabase.co/storage/v1/object/public/chat-attachments/<path>
  static const _publicMarker = '/object/public/$_storageBucket/';

  /// Extract the storage object path from whatever we stored in `file_url`.
  ///
  /// New messages store the bare path (e.g. `uid/receiver/123_file.jpg`).
  /// Old messages stored a full public URL — strip everything up to and
  /// including the bucket segment so those still resolve after the bucket is
  /// made private.
  String _storagePathOf(String stored) {
    final i = stored.indexOf(_publicMarker);
    if (i != -1) return stored.substring(i + _publicMarker.length);
    return stored; // already a bare path
  }

  /// Turn a stored `file_url` (path or legacy public URL) into a short-lived
  /// signed URL that a private bucket will serve to the two participants.
  Future<String> resolveMediaUrl(String stored) async {
    return _supabase.storage
        .from(_storageBucket)
        .createSignedUrl(_storagePathOf(stored), _signedUrlTtl);
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
    String? fileName,
    int? fileSize,
    int? duration,
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
      'duration': duration,
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
      // Store the object path (bucket is private); resolve to a signed URL on
      // read via resolveMediaUrl().
      'file_url': storagePath,
      'file_name': fileName,
      'file_size': fileSize,
      'message_type': isImage ? 'image' : 'file',
    };
  }

  Future<void> sendFileMessage({
    required String receiverId,
    required File file,
    String? caption,
  }) async {
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

  Future<void> sendVoiceMessage({
    required String receiverId,
    required String filePath,
    required int durationSeconds,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final file = File(filePath);
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    final storagePath = '$currentUserId/$receiverId/$fileName';

    await _supabase.storage.from(_storageBucket).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(contentType: 'audio/aac'),
        );

    await sendMessage(
      receiverId: receiverId,
      content: '',
      messageType: 'voice',
      fileUrl: storagePath,
      fileName: fileName,
      fileSize: await file.length(),
      duration: durationSeconds,
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

  /// Fetch one page of a conversation's history, newest-first.
  ///
  /// Pass [before] (the oldest loaded message's `created_at`) to page backwards
  /// for infinite scroll. Returns up to [limit] rows in descending order; the
  /// caller reverses them for ascending display.
  Future<List<Map<String, dynamic>>> fetchMessages(
    String otherUserId, {
    int limit = 25,
    DateTime? before,
  }) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return [];
    var query = _supabase.from('messages').select().or(
          'and(sender_id.eq.$me,receiver_id.eq.$otherUserId),'
          'and(sender_id.eq.$otherUserId,receiver_id.eq.$me)',
        );
    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }
    final rows =
        await query.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

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
