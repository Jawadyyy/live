import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:live/screens/agora_services/agora_stream_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveStreamScreen extends StatefulWidget {
  final Map<String, dynamic> streamData;
  const LiveStreamScreen({super.key, required this.streamData});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final _streamService = AgoraStreamService();
  final _supabase = Supabase.instance.client;
  bool _joined = false;
  bool _muted = false;
  bool _cameraOff = false;
  bool _isScreenSharing = false;
  bool _isEnding = false;
  int _viewerCount = 0;
  Duration _duration = Duration.zero;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initStream();
    _listenViewerCount();
  }

  Future<void> _initStream() async {
    try {
      await _streamService.initializeBroadcaster();
      _streamService.engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          if (!mounted) return;
          setState(() => _joined = true);
          _stopwatch.start();
          _startTimer();
        },
        onError: (err, msg) => debugPrint('Stream error: $err $msg'),
      ));
      await _streamService.joinAsBroadcaster(widget.streamData['stream_key']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start stream: $e')));
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
            setState(() => _viewerCount = data.first['viewer_count'] ?? 0);
          }
        });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _isEnding) return false;
      setState(() => _duration = _stopwatch.elapsed);
      return true;
    });
  }

  String get _durationText {
    final h = _duration.inHours;
    final m = _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _endStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Stream?'),
        content: const Text('Your stream will end for all viewers.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('End Stream')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isEnding = true);
    _stopwatch.stop();
    await _streamService.endStream(widget.streamData['id']);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        // Local video preview
        if (_joined &&
            _streamService.engine != null &&
            !_cameraOff &&
            !_isScreenSharing)
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _streamService.engine!,
              canvas: const VideoCanvas(uid: 0),
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
            child: Center(
              child: Icon(
                _isScreenSharing
                    ? Icons.screen_share_rounded
                    : Icons.videocam_off_rounded,
                size: 80,
                color: Colors.white12,
              ),
            ),
          ),

        // Top bar
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                // Live badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ]),
                ),
                const SizedBox(width: 10),
                // Duration
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_durationText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                // Viewer count
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.remove_red_eye_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text('$_viewerCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
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
              ]),
            ),
          ]),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ctrlBtn(
                      icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: _muted ? 'Unmute' : 'Mute',
                      active: _muted,
                      onTap: () async {
                        setState(() => _muted = !_muted);
                        await _streamService.toggleMute(_muted);
                      },
                    ),
                    _ctrlBtn(
                      icon: _cameraOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      label: _cameraOff ? 'Cam On' : 'Cam Off',
                      active: _cameraOff,
                      onTap: () async {
                        setState(() => _cameraOff = !_cameraOff);
                        await _streamService.toggleCamera(_cameraOff);
                      },
                    ),
                    _ctrlBtn(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      onTap: () => _streamService.switchCamera(),
                    ),
                    _ctrlBtn(
                      icon: _isScreenSharing
                          ? Icons.stop_screen_share_rounded
                          : Icons.screen_share_rounded,
                      label: _isScreenSharing ? 'Stop Share' : 'Screen',
                      active: _isScreenSharing,
                      onTap: () async {
                        if (_isScreenSharing) {
                          await _streamService.stopScreenShare();
                        } else {
                          await _streamService.startScreenShare();
                        }
                        setState(() => _isScreenSharing = !_isScreenSharing);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isEnding ? null : _endStream,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isEnding
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text('End Stream',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: active ? Colors.black87 : Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }

  @override
  void dispose() {
    _streamService.dispose();
    super.dispose();
  }
}
