import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:live/screens/agora_services/agora_call_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> friend;
  final String channelName;
  final String callId;
  final bool isIncoming;

  const VideoCallScreen({
    super.key,
    required this.friend,
    required this.channelName,
    required this.callId,
    this.isIncoming = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin {
  final _callService = AgoraCallService();
  int? _remoteUid;
  bool _muted = false,
      _cameraOff = false,
      _joined = false,
      _callEnded = false,
      _controlsVisible = true;

  final _stopwatch = Stopwatch();
  Duration _callDuration = Duration.zero;
  Timer? _hideTimer;

  // PiP
  Offset _pipOffset = const Offset(16, 120);
  bool _pipMinimized = false;

  late AnimationController _pulseController;
  late AnimationController _controlsController;
  late Animation<double> _pulseAnim;
  late Animation<double> _controlsAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.16).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _controlsAnim = CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeOut,
    );

    _initCall();
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _remoteUid != null) _setControls(false);
    });
  }

  void _setControls(bool visible) {
    setState(() => _controlsVisible = visible);
    if (visible) {
      _controlsController.forward();
      _scheduleHide();
    } else {
      _controlsController.reverse();
    }
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
          _scheduleHide();
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
        isVideo: true,
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
    _hideTimer?.cancel();
    await _callService.leaveAndUpdateStatus(
        callId: widget.callId, status: 'ended');
    if (mounted) Navigator.pop(context);
  }

  String get _timerText {
    final m = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _statusText {
    if (_remoteUid != null) return _timerText;
    if (_joined) return 'Ringing…';
    return 'Connecting…';
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulseController.dispose();
    _controlsController.dispose();
    _hideTimer?.cancel();
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => _setControls(!_controlsVisible),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Remote video full screen ──────────────────────────────────
            if (_remoteUid != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _callService.engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              )
            else
              _WaitingScreen(
                avatarUrl: widget.friend['avatar_url'],
                username: widget.friend['username'] ?? '?',
                pulseAnim: _pulseAnim,
                statusText: _statusText,
              ),

            // ── Draggable PiP ─────────────────────────────────────────────
            if (_joined)
              _DraggablePip(
                offset: _pipOffset,
                minimized: _pipMinimized,
                screenSize: size,
                onOffsetChanged: (o) => setState(() => _pipOffset = o),
                onTap: () {
                  setState(() => _pipMinimized = !_pipMinimized);
                },
                child: _cameraOff
                    ? _CameraOffView()
                    : AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _callService.engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
              ),

            // ── Top bar ───────────────────────────────────────────────────
            _AnimatedOverlay(
              animation: _controlsAnim,
              slideUp: true,
              child: _TopBar(
                username: widget.friend['username'] ?? 'Unknown',
                statusText: _statusText,
                connected: _remoteUid != null,
                onEnd: _endCall,
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _AnimatedOverlay(
                animation: _controlsAnim,
                slideUp: false,
                child: _BottomControls(
                  muted: _muted,
                  cameraOff: _cameraOff,
                  onMute: () async {
                    setState(() => _muted = !_muted);
                    await _callService.toggleMute(_muted);
                    _setControls(true);
                  },
                  onCamera: () async {
                    setState(() => _cameraOff = !_cameraOff);
                    await _callService.toggleCamera(_cameraOff);
                    _setControls(true);
                  },
                  onFlip: () {
                    _callService.switchCamera();
                    _setControls(true);
                  },
                  onEndCall: _endCall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Waiting screen (before remote joins) ─────────────────────────────────────
class _WaitingScreen extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final Animation<double> pulseAnim;
  final String statusText;

  const _WaitingScreen({
    required this.avatarUrl,
    required this.username,
    required this.pulseAnim,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (avatarUrl != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
            child: Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.62),
              colorBlendMode: BlendMode.darken,
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0A1E), Color(0xFF1C1040)],
              ),
            ),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulseAvatar(
                avatarUrl: avatarUrl,
                username: username,
                pulseAnim: pulseAnim,
              ),
              const SizedBox(height: 22),
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              _BouncingDots(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pulse avatar ──────────────────────────────────────────────────────────────
class _PulseAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final Animation<double> pulseAnim;

  const _PulseAvatar({
    required this.avatarUrl,
    required this.username,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: pulseAnim.value * 1.14,
              child: Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C56E1).withOpacity(0.07),
                ),
              ),
            ),
            Transform.scale(
              scale: pulseAnim.value,
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C56E1).withOpacity(0.13),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C56E1).withOpacity(0.45),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                backgroundColor: const Color(0xFF3D2270),
                child: avatarUrl == null
                    ? Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Draggable PiP ─────────────────────────────────────────────────────────────
class _DraggablePip extends StatelessWidget {
  final Offset offset;
  final bool minimized;
  final Size screenSize;
  final ValueChanged<Offset> onOffsetChanged;
  final VoidCallback onTap;
  final Widget child;

  const _DraggablePip({
    required this.offset,
    required this.minimized,
    required this.screenSize,
    required this.onOffsetChanged,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final w = minimized ? 58.0 : 112.0;
    final h = minimized ? 58.0 : 162.0;

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (d) {
          final next = offset + d.delta;
          onOffsetChanged(Offset(
            next.dx.clamp(8, screenSize.width - w - 8),
            next.dy.clamp(8, screenSize.height - h - 8),
          ));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(minimized ? 29 : 20),
            border: Border.all(
              color: Colors.white.withOpacity(0.32),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(minimized ? 29 : 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CameraOffView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: const Center(
        child:
            Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 28),
      ),
    );
  }
}

// ── Animated overlay wrapper ───────────────────────────────────────────────────
class _AnimatedOverlay extends StatelessWidget {
  final Animation<double> animation;
  final bool slideUp;
  final Widget child;

  const _AnimatedOverlay({
    required this.animation,
    required this.slideUp,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, c) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(
            0,
            slideUp ? (animation.value - 1) * 50 : (1 - animation.value) * 80,
          ),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String username;
  final String statusText;
  final bool connected;
  final VoidCallback onEnd;

  const _TopBar({
    required this.username,
    required this.statusText,
    required this.connected,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.75),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              // Glass back button
              _GlassBtn(
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: onEnd,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (connected)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: connected
                                ? const Color(0xFF4ADE80)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight:
                                connected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom controls ───────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final bool muted, cameraOff;
  final VoidCallback onMute, onCamera, onFlip, onEndCall;

  const _BottomControls({
    required this.muted,
    required this.cameraOff,
    required this.onMute,
    required this.onCamera,
    required this.onFlip,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CtrlBtn(
                      icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: muted ? 'Unmute' : 'Mute',
                      active: muted,
                      onTap: onMute,
                    ),
                    _CtrlBtn(
                      icon: cameraOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      label: cameraOff ? 'Cam On' : 'Cam Off',
                      active: cameraOff,
                      onTap: onCamera,
                    ),
                    _CtrlBtn(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      onTap: onFlip,
                    ),
                    // End call
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onEndCall,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFEF4444).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('End',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.92)
                  : Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(active ? 0 : 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: active ? Colors.black87 : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass button ──────────────────────────────────────────────────────────────
class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Bouncing dots ─────────────────────────────────────────────────────────────
class _BouncingDots extends StatefulWidget {
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final t = (_ctrl.value - delay).clamp(0.0, 1.0);
          final opacity =
              (0.25 + 0.75 * (t < 0.5 ? t * 2 : (1 - t) * 2)).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
