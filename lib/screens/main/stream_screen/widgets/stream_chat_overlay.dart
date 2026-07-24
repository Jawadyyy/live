import 'package:flutter/material.dart';

import '../services/stream_chat_controller.dart';

const _quickEmojis = ['❤️', '😂', '🔥', '👏', '😮', '🎉'];

/// Translucent chat layer over the bottom of the video (fullscreen-overlay
/// layout). Message list fades into the video at its top; input + quick
/// reactions dock at the bottom. Non-friends see a "add friend to chat" hint.
class StreamChatOverlay extends StatefulWidget {
  final StreamChatController controller;

  /// Extra bottom padding so the input clears system controls / end-stream bar.
  final double bottomInset;
  const StreamChatOverlay({
    super.key,
    required this.controller,
    this.bottomInset = 0,
  });

  @override
  State<StreamChatOverlay> createState() => _StreamChatOverlayState();
}

class _StreamChatOverlayState extends State<StreamChatOverlay> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  bool _hasNew = false;
  int _lastCount = 0;

  StreamChatController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChange);
  }

  bool get _atBottom {
    if (!_scroll.hasClients) return true;
    return _scroll.position.pixels >= _scroll.position.maxScrollExtent - 48;
  }

  void _onChange() {
    if (!mounted) return;
    final count = _c.feed.length;
    if (count != _lastCount) {
      final grew = count > _lastCount;
      _lastCount = count;
      if (grew) {
        if (_atBottom) {
          _scrollToBottom();
        } else {
          setState(() => _hasNew = true);
        }
      }
    }
    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
    if (_hasNew) setState(() => _hasNew = false);
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _c.send(text);
    _input.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = _c.feed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Messages (bottom third), fading into the video at the top ──
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.34,
          ),
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black, Colors.black],
              stops: [0.0, 0.18, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: Stack(
              children: [
                if (feed.isEmpty)
                  const SizedBox.shrink()
                else
                  ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
                    itemCount: feed.length,
                    itemBuilder: (_, i) => _MessageLine(
                      message: feed[i],
                      controller: _c,
                    ),
                  ),
                if (_hasNew)
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: Center(child: _NewMessagePill(onTap: _scrollToBottom)),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 6),
        // ── Composer / hint ──
        Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + widget.bottomInset),
          child: _c.canChat ? _composer() : _cannotChatHint(),
        ),
      ],
    );
  }

  Widget _composer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Quick reactions strip
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            children: [
              for (final e in _quickEmojis)
                GestureDetector(
                  onTap: () => _c.sendReaction(e),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: _input,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                maxLength: 500,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'Say something…',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7C56E1), Color(0xFFA37BFF)],
                ),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _cannotChatHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: const Row(children: [
        Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Add this streamer as a friend to join the chat',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ]),
    );
  }
}

class _MessageLine extends StatelessWidget {
  final Map<String, dynamic> message;
  final StreamChatController controller;
  const _MessageLine({required this.message, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (message['type'] == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Center(
          child: Text(
            message['text'] ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final userId = message['user_id'] as String;
    final user = controller.userFor(userId);
    final username = user['username'] as String? ?? 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onLongPress: controller.canDelete(message)
            ? () => _confirmDelete(context)
            : null,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(14),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, height: 1.3),
                children: [
                  TextSpan(
                    text: '$username ',
                    style: TextStyle(
                      color: StreamChatController.colorFor(username),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: message['content'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1040),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          title: const Text('Delete message',
              style: TextStyle(color: Colors.white)),
          onTap: () {
            controller.delete(message['id'] as String);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _NewMessagePill extends StatelessWidget {
  final VoidCallback onTap;
  const _NewMessagePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF7C56E1),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 14),
          SizedBox(width: 5),
          Text('New messages',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
