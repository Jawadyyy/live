import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:live/screens/agora_services/agora_call_service.dart';

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
  bool _muted = false;
  bool _cameraOff = false;
  bool _speakerOn = true;
  bool _joined = false;
  bool _callEnded = false;
  Duration _callDuration = Duration.zero;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _initCall();
  }

  Future<void> _initCall() async {
    await _callService.initialize();

    _callService.engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _joined = true);
          _stopwatch.start();
          _startTimer();
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUid = null);
          _endCall();
        },
        onError: (err, msg) {
          debugPrint('Agora error: $err - $msg');
        },
      ),
    );

    await _callService.joinChannel(
      channelName: widget.channelName,
      isVideo: widget.isVideo,
    );
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
      callId: widget.callId,
      status: 'ended',
    );
    if (mounted) Navigator.pop(context);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Remote video or voice background
          if (widget.isVideo && _remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _callService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            )
          else
            _buildCallBackground(),

          // Local video PiP
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

          // Dark gradient overlay at top and bottom
          Positioned.fill(
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top: caller info
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundImage: widget.friend['avatar_url'] != null
                        ? NetworkImage(widget.friend['avatar_url'])
                        : null,
                    backgroundColor: Colors.white24,
                    child: widget.friend['avatar_url'] == null
                        ? Text(
                            (widget.friend['username']?[0] ?? '?')
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.friend['username'] ?? 'Unknown',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _remoteUid != null
                        ? _formatDuration(_callDuration)
                        : _joined
                            ? 'Ringing...'
                            : 'Connecting...',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: Column(
                  children: [
                    // Secondary controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _controlButton(
                          icon: _muted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          label: _muted ? 'Unmute' : 'Mute',
                          active: _muted,
                          onTap: () async {
                            setState(() => _muted = !_muted);
                            await _callService.toggleMute(_muted);
                          },
                        ),
                        if (widget.isVideo)
                          _controlButton(
                            icon: Icons.flip_camera_ios_rounded,
                            label: 'Flip',
                            onTap: () => _callService.switchCamera(),
                          ),
                        if (widget.isVideo)
                          _controlButton(
                            icon: _cameraOff
                                ? Icons.videocam_off_rounded
                                : Icons.videocam_rounded,
                            label: _cameraOff ? 'Cam on' : 'Cam off',
                            active: _cameraOff,
                            onTap: () async {
                              setState(() => _cameraOff = !_cameraOff);
                              await _callService.toggleCamera(_cameraOff);
                            },
                          )
                        else
                          _controlButton(
                            icon: _speakerOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            label: _speakerOn ? 'Speaker' : 'Earpiece',
                            active: !_speakerOn,
                            onTap: () {
                              setState(() => _speakerOn = !_speakerOn);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // End call button
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallBackground() {
    return Container(
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
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: active ? Colors.black87 : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }
}
