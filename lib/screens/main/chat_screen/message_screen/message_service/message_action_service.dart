import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageActionService {
  final _supabase = Supabase.instance.client;

  Future<void> editMessage({
    required BuildContext context,
    required Map<String, dynamic> message,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    final colors = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: message['content'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.edit_rounded, color: colors.primary, size: 20),
          const SizedBox(width: 8),
          const Text('Edit Message',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ]),
        content: TextField(
          controller: controller,
          maxLines: 4,
          minLines: 1,
          autofocus: true,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            filled: true,
            fillColor: colors.surfaceVariant.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty || newText == message['content']) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              try {
                await _supabase
                    .from('messages')
                    .update({'content': newText}).eq('id', message['id']);
                onSuccess();
              } catch (e) {
                onError();
              }
            },
            child: const Text('Save', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> confirmDelete({
    required BuildContext context,
    required String messageId,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    final colors = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Delete Message',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ]),
        content: const Text(
          'This message will be permanently deleted. This action cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabase.from('messages').delete().eq('id', messageId);
                onSuccess();
              } catch (e) {
                onError();
              }
            },
            child: const Text('Delete', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void copyToClipboard({
    required String text,
    required VoidCallback onCopied,
  }) {
    Clipboard.setData(ClipboardData(text: text));
    onCopied();
  }
}
