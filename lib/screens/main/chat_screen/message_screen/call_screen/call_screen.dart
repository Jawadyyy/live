import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:live/screens/agora_services/agora_call_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> friend;
  final String channelName;
  final String callId;
  final bool isVideo;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.friend,
    required this.channelName,
    required this.callId,
    required this.isVideo,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _callService = AgoraCallService();
  int? _remoteUid;
  bool _muted = false, _cameraOff = false, _joined = false, _callEnded = false;
  final _stopwatch = Stopwatch();
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    try {
      await _callService.initialize();

      if (widget.isIncoming) {
        await Supabase.instance.client
            .from('calls')
            .update({'status': 'accepted'}).eq('id', widget.callId);
      }

      _callService.engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (!mounted) return;
          setState(() => _joined = true);
          _stopwatch.start();
          _startTimer();
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!mounted) return;
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted) return;
          setState(() => _remoteUid = null);
          _endCall();
        },
        onError: (err, msg) => debugPrint('Agora error: $err $msg'),
      ));

      await _callService.joinChannel(
        channelName: widget.channelName,
        isVideo: widget.isVideo,
      );
    } catch (e) {
      debugPrint('Call init error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _callEnded) return false;
      setState(() => _callDuration = _stopwatch.elapsed);
      return true;
    });
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    setState(() => _callEnded = true);
    _stopwatch.stop();
    await _callService.leaveAndUpdateStatus(
        callId: widget.callId, status: 'ended');
    if (mounted) Navigator.pop(context);
  }

  String get _durationText {
    final m = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (widget.isVideo && _remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _callService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            )
          else
            _buildVoiceBg(),

          // Gradient overlays
          _buildGradient(Alignment.topCenter, Alignment.bottomCenter),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildGradient(Alignment.bottomCenter, Alignment.topCenter),
          ),

          // Local PiP
          if (widget.isVideo && _joined)
            Positioned(
              top: 60,
              right: 16,
              width: 110,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _callService.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),

          // Top info
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: widget.friend['avatar_url'] != null
                      ? NetworkImage(widget.friend['avatar_url'])
                      : null,
                  backgroundColor: const Color(0xFF7C56E1),
                  child: widget.friend['avatar_url'] == null
                      ? Text(
                          (widget.friend['username']?[0] ?? '?').toUpperCase(),
                          style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(widget.friend['username'] ?? 'Unknown',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _remoteUid != null
                      ? _durationText
                      : _joined
                          ? 'Ringing...'
                          : 'Connecting...',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ]),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ctrlBtn(
                        icon:
                            _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _muted ? 'Unmute' : 'Mute',
                        active: _muted,
                        onTap: () async {
                          setState(() => _muted = !_muted);
                          await _callService.toggleMute(_muted);
                        },
                      ),
                      if (widget.isVideo) ...[
                        _ctrlBtn(
                            icon: Icons.flip_camera_ios_rounded,
                            label: 'Flip',
                            onTap: _callService.switchCamera),
                        _ctrlBtn(
                          icon: _cameraOff
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          label: _cameraOff ? 'Cam on' : 'Cam off',
                          active: _cameraOff,
                          onTap: () async {
                            setState(() => _cameraOff = !_cameraOff);
                            await _callService.toggleCamera(_cameraOff);
                          },
                        ),
                      ] else
                        _ctrlBtn(
                            icon: Icons.volume_up_rounded,
                            label: 'Speaker',
                            onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.call_end_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1040), Color(0xFF0D0822), Color(0xFF130830)],
          ),
        ),
        child: Center(
            child: Icon(
          widget.isVideo ? Icons.videocam_off_rounded : Icons.mic_rounded,
          size: 80,
          color: Colors.white12,
        )),
      );

  Widget _buildGradient(Alignment begin, Alignment end) => Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
      );

  Widget _ctrlBtn(
      {required IconData icon,
      required String label,
      bool active = false,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: active ? Colors.black87 : Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }
}
