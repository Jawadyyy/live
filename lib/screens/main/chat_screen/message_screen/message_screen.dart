import 'dart:io';
import 'package:flutter/material.dart';
import 'package:live/screens/agora_services/agora_call_service.dart';
import 'package:live/screens/main/chat_screen/message_screen/call_screens/video_call.dart';
import 'package:live/screens/main/chat_screen/message_screen/call_screens/voice_call.dart';
import 'package:live/screens/main/chat_screen/message_screen/widgets/voice_message_bubble.dart';
import 'package:live/screens/main/chat_screen/message_screen/widgets/voice_recorder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live/screens/main/chat_screen/message_screen/message_service/message_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class MessageScreen extends StatefulWidget {
  final Map<String, dynamic> friend;
  const MessageScreen({super.key, required this.friend});
  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _messageService = MessageService();
  final _supabase = Supabase.instance.client;
  late FocusNode _messageFocusNode;
  late Stream<List<Map<String, dynamic>>> _messagesStream;
  List<Map<String, dynamic>> _cachedMessages = [];
  bool _showEmojiPicker = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _initialScrollDone = false;
  bool _isRecording = false; // NEW

  @override
  void initState() {
    super.initState();
    _messageFocusNode = FocusNode();
    _messagesStream = _messageService.getMessagesStream(widget.friend['id']);
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _messageService.markAllAsRead(widget.friend['id']);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _startVideoCall() async {
    try {
      final callData = await AgoraCallService().initiateCall(
        receiverId: widget.friend['id'],
        callType: 'video',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            friend: widget.friend,
            channelName: callData['channel_name'],
            callId: callData['id'],
            isIncoming: false,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Could not start video call');
    }
  }

  Future<void> _startVoiceCall() async {
    try {
      final callData = await AgoraCallService().initiateCall(
        receiverId: widget.friend['id'],
        callType: 'voice',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceCallScreen(
            friend: widget.friend,
            channelName: callData['channel_name'],
            callId: callData['id'],
            isIncoming: false,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Could not start voice call');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try {
      await _messageService.sendMessage(
          receiverId: widget.friend['id'], content: text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Failed to send message');
    }
  }

  // NEW
  Future<void> _sendVoiceMessage(String filePath, int duration) async {
    setState(() => _isRecording = false);
    try {
      await _messageService.sendVoiceMessage(
        receiverId: widget.friend['id'],
        filePath: filePath,
        durationSeconds: duration,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to send voice message');
    }
  }

  void _scrollToBottomInstant() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _messageFocusNode.requestFocus();
    } else {
      _messageFocusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {}

  void _showAttachmentOptions() {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          Text('Share Attachment',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _attachOption(Icons.photo_library_rounded, 'Gallery', Colors.purple,
                () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            }),
            _attachOption(Icons.camera_alt_rounded, 'Camera', Colors.blue, () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            }),
            _attachOption(
                Icons.insert_drive_file_rounded, 'File', Colors.orange, () {
              Navigator.pop(ctx);
              _pickFile();
            }),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _attachOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700])),
      ]),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, imageQuality: 75, maxWidth: 1200);
      if (picked == null) return;
      await _uploadAndSend(File(picked.path));
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to pick image');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      await _uploadAndSend(File(path));
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to pick file');
    }
  }

  Future<void> _uploadAndSend(File file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });
    try {
      for (var i = 1; i <= 3; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() => _uploadProgress = i * 0.25);
      }
      await _messageService.sendFileMessage(
          receiverId: widget.friend['id'], file: file);
      if (mounted) setState(() => _uploadProgress = 1.0);
      _scrollToBottom();
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to send file');
    } finally {
      if (mounted)
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildUserAvatar({double radius = 20}) {
    return Hero(
      tag: 'avatar_${widget.friend['id']}',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        backgroundImage: widget.friend['avatar_url'] != null
            ? NetworkImage(widget.friend['avatar_url'])
            : null,
        child: widget.friend['avatar_url'] == null
            ? Icon(Icons.person, size: radius, color: Colors.grey[600])
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentUserId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: Row(
          children: [
            _buildUserAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend['username'] ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text('Online',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child:
                  Icon(Icons.videocam_rounded, size: 22, color: colors.primary),
            ),
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.call_rounded, size: 22, color: colors.primary),
            ),
            onPressed: _startVoiceCall,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        if (_isUploading)
          LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: colors.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(colors.primary),
              minHeight: 3),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.primary.withOpacity(0.03), colors.surface],
              ),
            ),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  _cachedMessages = snapshot.data!;
                }

                if (_cachedMessages.isEmpty) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: colors.primary)),
                          const SizedBox(height: 16),
                          Text('Loading messages...',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.error_outline_rounded,
                                    size: 48, color: Colors.redAccent)),
                            const SizedBox(height: 16),
                            Text('Couldn\'t load messages',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 20),
                            FilledButton.tonal(
                                onPressed: () => setState(() {}),
                                child: const Text('Try Again')),
                          ],
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: colors.primary.withOpacity(0.2),
                                      width: 3)),
                              child: _buildUserAvatar(radius: 50)),
                          const SizedBox(height: 24),
                          Text(widget.friend['username'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('Say hello! 👋',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[600])),
                          const SizedBox(height: 6),
                          Text(
                              'Send your first message to start the conversation',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500]),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                if (!_initialScrollDone) {
                  _initialScrollDone = true;
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottomInstant());
                } else {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _cachedMessages.length,
                  itemBuilder: (context, index) {
                    final message = _cachedMessages[index];
                    final isMe = message['sender_id'] == currentUserId;
                    final showAvatar = index == 0 ||
                        _cachedMessages[index - 1]['sender_id'] !=
                            message['sender_id'];
                    final createdAt = message['created_at'] != null
                        ? DateTime.parse(message['created_at']).toLocal()
                        : null;

                    Widget? dateSeparator;
                    if (createdAt != null) {
                      if (index == 0) {
                        dateSeparator = _buildDateSeparator(createdAt);
                      } else {
                        final prevCreatedAt = _cachedMessages[index - 1]
                                    ['created_at'] !=
                                null
                            ? DateTime.parse(
                                    _cachedMessages[index - 1]['created_at'])
                                .toLocal()
                            : null;
                        if (prevCreatedAt == null ||
                            !_isSameDay(createdAt, prevCreatedAt)) {
                          dateSeparator = _buildDateSeparator(createdAt);
                        }
                      }
                    }

                    return Column(children: [
                      if (dateSeparator != null) dateSeparator,
                      _buildMessageBubble(
                          message: message,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          timestamp: createdAt,
                          isLast: index == _cachedMessages.length - 1),
                    ]);
                  },
                );
              },
            ),
          ),
        ),

        // UPDATED: show recorder or normal input
        if (_isRecording)
          VoiceRecorder(
            onSend: _sendVoiceMessage,
            onCancel: () => setState(() => _isRecording = false),
          )
        else
          _buildInputArea(colors, theme),

        if (_showEmojiPicker && !_isRecording)
          SizedBox(
            height: 280,
            child: EmojiPicker(
              textEditingController: _messageController,
              onEmojiSelected: _onEmojiSelected,
              config: Config(
                height: 280,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28 *
                      (Theme.of(context).platform == TargetPlatform.iOS
                          ? 1.2
                          : 1.0),
                  backgroundColor: colors.surface,
                ),
                categoryViewConfig: CategoryViewConfig(
                  indicatorColor: colors.primary,
                  iconColorSelected: colors.primary,
                  iconColor: Colors.grey,
                  backgroundColor: colors.surface,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: colors.surface,
                ),
                bottomActionBarConfig:
                    const BottomActionBarConfig(enabled: false),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600])),
      )),
    );
  }

  Widget _buildInputArea(ColorScheme colors, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
          top: false,
          child: Row(children: [
            // Attachment button
            GestureDetector(
              onTap: _showAttachmentOptions,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.add_rounded, size: 24, color: colors.primary),
              ),
            ),
            const SizedBox(width: 10),
            // Text field
            Expanded(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(children: [
                Expanded(
                    child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey)),
                  onTap: () {
                    if (_showEmojiPicker)
                      setState(() => _showEmojiPicker = false);
                  },
                  onSubmitted: (_) => _sendMessage(),
                )),
                GestureDetector(
                  onTap: _toggleEmojiPicker,
                  child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                          _showEmojiPicker
                              ? Icons.keyboard_rounded
                              : Icons.emoji_emotions_outlined,
                          color: _showEmojiPicker
                              ? colors.primary
                              : Colors.grey[500],
                          size: 24)),
                ),
              ]),
            )),
            const SizedBox(width: 10),
            // Mic button - NEW
            GestureDetector(
              onTap: () => setState(() => _isRecording = true),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.mic_rounded, color: colors.primary, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    colors.primary,
                    colors.primary.withOpacity(0.8)
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ])),
    );
  }

  Widget _buildMessageBubble({
    required Map<String, dynamic> message,
    required bool isMe,
    required bool showAvatar,
    required bool isLast,
    DateTime? timestamp,
  }) {
    final colors = Theme.of(context).colorScheme;
    final content = message['content'] ?? '';
    final isRead = message['is_read'] ?? false;
    final messageType = message['message_type'] ?? 'text';
    final fileUrl = message['file_url'];
    final fileName = message['file_name'] ?? 'File';
    final fileSize = message['file_size'];
    final duration = message['duration'];

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 4 : 6, top: showAvatar ? 6 : 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.friend['avatar_url'] != null
                      ? NetworkImage(widget.friend['avatar_url'])
                      : null,
                  child: widget.friend['avatar_url'] == null
                      ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                      : null,
                ))
          else if (!isMe)
            const SizedBox(width: 40),
          Flexible(
              child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: isMe
                      ? colors.primary
                      : colors.surfaceContainerHighest.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: _buildBubbleContent(messageType, content, fileUrl,
                    fileName, fileSize, duration, isMe, colors),
              ),
              if (timestamp != null)
                Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(timeago.format(timestamp),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500])),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                            isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 14,
                            color: isRead
                                ? Colors.lightBlueAccent
                                : Colors.grey[500]),
                      ],
                    ])),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(
      String type,
      String content,
      String? fileUrl,
      String fileName,
      int? fileSize,
      int? duration, // NEW param
      bool isMe,
      ColorScheme colors) {
    switch (type) {
      // NEW voice case
      case 'voice':
        return VoiceMessageBubble(
          audioUrl: fileUrl!,
          durationSeconds: duration ?? 0,
          isMe: isMe,
          colors: colors,
        );
      case 'image':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft:
                  Radius.circular(content.isNotEmpty ? 0 : (isMe ? 20 : 4)),
              bottomRight:
                  Radius.circular(content.isNotEmpty ? 0 : (isMe ? 4 : 20)),
            ),
            child: Image.network(
              fileUrl!,
              width: 240,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                    width: 240,
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null)));
              },
              errorBuilder: (ctx, err, stack) => Container(
                  width: 240,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.grey))),
            ),
          ),
          if (content.isNotEmpty)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(content,
                    style: TextStyle(
                        color: isMe ? Colors.white : colors.onSurface,
                        fontSize: 14,
                        height: 1.4))),
        ]);
      case 'file':
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color:
                      (isMe ? Colors.white : colors.primary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_getFileIcon(fileName),
                  size: 22, color: isMe ? Colors.white : colors.primary),
            ),
            const SizedBox(width: 10),
            Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(fileName,
                      style: TextStyle(
                          color: isMe ? Colors.white : colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (fileSize != null)
                    Text(_formatFileSize(fileSize),
                        style: TextStyle(
                            color: (isMe ? Colors.white : Colors.grey[600])!
                                .withOpacity(0.7),
                            fontSize: 12)),
                ])),
          ]),
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(content,
              style: TextStyle(
                  color: isMe ? Colors.white : colors.onSurface,
                  fontSize: 15,
                  height: 1.4)),
        );
    }
  }

  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack_rounded;
      case 'mp4':
      case 'mov':
        return Icons.videocam_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }
}
