import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageOptionsSheet extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool isPinned;
  final VoidCallback onCopy;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MessageOptionsSheet({
    super.key,
    required this.message,
    required this.isMe,
    required this.isPinned,
    required this.onCopy,
    required this.onPin,
    required this.onEdit,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> message,
    required bool isMe,
    required bool isPinned,
    required VoidCallback onCopy,
    required VoidCallback onPin,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MessageOptionsSheet(
        message: message,
        isMe: isMe,
        isPinned: isPinned,
        onCopy: onCopy,
        onPin: onPin,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final messageType = message['message_type'] ?? 'text';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),

          // Message preview
          if (messageType == 'text')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message['content'] ?? '',
                style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withOpacity(0.7),
                    height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          if (messageType == 'voice')
            _previewTile(
              icon: Icons.mic_rounded,
              label: 'Voice message',
              color: colors.primary,
            ),

          if (messageType == 'image')
            _previewTile(
              icon: Icons.image_rounded,
              label: 'Image',
              color: Colors.purple,
            ),

          if (messageType == 'file')
            _previewTile(
              icon: Icons.insert_drive_file_rounded,
              label: message['file_name'] ?? 'File',
              color: Colors.orange,
            ),

          // Actions
          _actionTile(
            icon: Icons.copy_rounded,
            label: 'Copy',
            color: colors.primary,
            onTap: () {
              Navigator.pop(context);
              onCopy();
            },
            show: messageType == 'text',
          ),

          _actionTile(
            icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: isPinned ? 'Unpin Message' : 'Pin Message',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              onPin();
            },
          ),

          _actionTile(
            icon: Icons.edit_rounded,
            label: 'Edit Message',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
            show: isMe && messageType == 'text',
          ),

          _actionTile(
            icon: Icons.delete_rounded,
            label: 'Delete Message',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
            show: isMe,
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _previewTile({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 14, color: color, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool show = true,
  }) {
    if (!show) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: label == 'Delete Message' ? Colors.red : null,
            ),
          ),
        ]),
      ),
    );
  }
}
