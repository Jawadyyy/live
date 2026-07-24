import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:live/screens/agora_services/agora_stream_service.dart';
import 'package:live/screens/main/stream_screen/services/stream_chat_controller.dart';
import 'package:live/screens/main/stream_screen/widgets/floating_reactions.dart';
import 'package:live/screens/main/stream_screen/widgets/stream_chat_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WatchStreamScreen extends StatefulWidget {
  final Map<String, dynamic> streamData;
  const WatchStreamScreen({super.key, required this.streamData});

  @override
  State<WatchStreamScreen> createState() => _WatchStreamScreenState();
}

class _WatchStreamScreenState extends State<WatchStreamScreen> {
  final _streamService = AgoraStreamService();
  final _supabase = Supabase.instance.client;
  late final StreamChatController _chat;

  int? _remoteUid;
  bool _joined = false;
  int _viewerCount = 0;
  Map<String, dynamic>? _host;

  String get _streamKey => widget.streamData['stream_key'];
  String get _streamId => widget.streamData['id'];

  @override
  void initState() {
    super.initState();
    _chat = StreamChatController(
      streamId: _streamId,
      hostId: widget.streamData['user_id'],
    );
    _fetchHost();
    _initViewer();
    _listenViewerCount();
  }

  Future<void> _fetchHost() async {
    try {
      final host = await _supabase
          .from('users')
          .select('username, avatar_url')
          .eq('id', widget.streamData['user_id'])
          .maybeSingle();
      if (mounted) setState(() => _host = host);
    } catch (_) {}
  }

  Future<void> _initViewer() async {
    try {
      await _streamService.initializeAudience();
      _streamService.engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          if (!mounted) return;
          setState(() => _joined = true);
          _streamService.updateViewerCount(_streamId, 1);
        },
        onUserJoined: (_, uid, __) {
          if (!mounted) return;
          setState(() => _remoteUid = uid);
        },
        onUserOffline: (_, uid, __) {
          if (!mounted) return;
          setState(() => _remoteUid = null);
        },
        onError: (err, msg) => debugPrint('Viewer error: $err $msg'),
      ));
      await _streamService.joinAsAudience(_streamKey);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to join stream: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _listenViewerCount() {
    _supabase
        .from('streams')
        .stream(primaryKey: ['id'])
        .eq('id', _streamId)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            if (data.first['status'] == 'ended') _showStreamEndedDialog();
            setState(() => _viewerCount = data.first['viewer_count'] ?? 0);
          }
        });
  }

  void _showStreamEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Stream Ended'),
        content: const Text('The streamer has ended the broadcast.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveStream() async {
    await _streamService.leaveAsAudience(_streamId);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _chat.dispose();
    _streamService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(fit: StackFit.expand, children: [
        _videoLayer(),

        // Bottom scrim for chat legibility.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating reactions rise over the video.
        FloatingReactions(reactions: _chat.reactions),

        // Chat overlay pinned to the bottom, lifts with the keyboard.
        Positioned(
          left: 0,
          right: 0,
          bottom: keyboard,
          child: SafeArea(
            top: false,
            child: AnimatedBuilder(
              animation: _chat,
              builder: (_, __) =>
                  StreamChatOverlay(controller: _chat, bottomInset: 4),
            ),
          ),
        ),

        // Persistent top bar with host chip + live/viewer pills.
        _topBar(),
      ]),
    );
  }

  Widget _videoLayer() {
    if (_remoteUid != null && _streamService.engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _streamService.engine!,
          canvas: VideoCanvas(
            uid: _remoteUid,
            renderMode: RenderModeType.renderModeHidden,
          ),
          connection: RtcConnection(channelId: _streamKey),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1040), Color(0xFF0D0822)],
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (widget.streamData['thumbnail_url'] != null)
          CircleAvatar(
            radius: 56,
            backgroundImage:
                CachedNetworkImageProvider(widget.streamData['thumbnail_url']),
          ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(
            color: Color(0xFF7C56E1), strokeWidth: 2),
        const SizedBox(height: 16),
        Text(
          _joined ? 'Waiting for streamer…' : 'Connecting to stream…',
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ]),
    );
  }

  Widget _topBar() {
    final username = _host?['username'] as String? ?? '';
    final avatarUrl = _host?['avatar_url'] as String?;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          // Back
          _glassButton(
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onTap: _leaveStream,
          ),
          const SizedBox(width: 10),
          // Host chip
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFF7C56E1), Color(0xFFA37BFF)]),
                  ),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFF1A1A2E),
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username.isEmpty ? 'Live' : username,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.streamData['title'] ?? '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          const _LivePill(),
          const SizedBox(width: 6),
          // Viewers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.remove_red_eye_rounded,
                  color: Colors.white, size: 13),
              const SizedBox(width: 5),
              Text('$_viewerCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _glassButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

/// Animated red LIVE pill (pulsing dot).
class _LivePill extends StatefulWidget {
  const _LivePill();
  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(duration: const Duration(seconds: 1), vsync: this)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        FadeTransition(
          opacity: _ctrl,
          child: Container(
            width: 6,
            height: 6,
            decoration:
                const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 5),
        const Text('LIVE',
            style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      ]),
    );
  }
}
