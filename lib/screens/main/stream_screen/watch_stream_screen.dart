import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:live/screens/agora_services/agora_stream_service.dart';
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
  int? _remoteUid;
  bool _joined = false;
  int _viewerCount = 0;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _initViewer();
    _listenViewerCount();
    _hideControlsAfterDelay();
  }

  Future<void> _initViewer() async {
    try {
      await _streamService.initializeAudience();
      _streamService.engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          if (!mounted) return;
          setState(() => _joined = true);
          _streamService.updateViewerCount(widget.streamData['id'], 1);
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
      await _streamService.joinAsAudience(widget.streamData['stream_key']);
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
        .eq('id', widget.streamData['id'])
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final status = data.first['status'];
            if (status == 'ended') {
              _showStreamEndedDialog();
            }
            setState(() => _viewerCount = data.first['viewer_count'] ?? 0);
          }
        });
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _controlsVisible = false);
      });
    }
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
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveStream() async {
    await _streamService.leaveAsAudience(widget.streamData['id']);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(fit: StackFit.expand, children: [
          // Remote video
          if (_remoteUid != null && _streamService.engine != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _streamService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection:
                    RtcConnection(channelId: widget.streamData['stream_key']),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1040), Color(0xFF0D0822)],
                ),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.streamData['thumbnail_url'] != null)
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            NetworkImage(widget.streamData['thumbnail_url']),
                      ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                        color: Color(0xFF7C56E1), strokeWidth: 2),
                    const SizedBox(height: 16),
                    const Text('Connecting to stream...',
                        style: TextStyle(color: Colors.white60, fontSize: 14)),
                  ]),
            ),

          // Top bar (animated)
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  // Back button
                  GestureDetector(
                    onTap: _leaveStream,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stream title
                  Expanded(
                    child: Text(
                      widget.streamData['title'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Live badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(width: 8),
                  // Viewer count
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black45,
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
            ),
          ),

          // Bottom streamer info
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.streamData['description'] != null &&
                          widget.streamData['description']
                              .toString()
                              .isNotEmpty)
                        Text(
                          widget.streamData['description'],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _streamService.dispose();
    super.dispose();
  }
}
