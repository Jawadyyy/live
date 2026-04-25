import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  final _callService = AgoraCallService();
  int? _remoteUid;
  bool _muted = false,
      _cameraOff = false,
      _joined = false,
      _callEnded = false,
      _speakerOn = true,
      _controlsVisible = true;

  final _stopwatch = Stopwatch();
  Duration _callDuration = Duration.zero;
  Timer? _hideControlsTimer;

  // PiP drag position
  Offset _pipOffset = const Offset(16, 120);
  bool _pipMinimized = false;

  // Animations
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
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _controlsAnim = CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeOut,
    );

    _initCall();
    if (widget.isVideo) _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _remoteUid != null) _setControlsVisible(false);
    });
  }

  void _setControlsVisible(bool visible) {
    setState(() => _controlsVisible = visible);
    if (visible) {
      _controlsController.forward();
      _scheduleHideControls();
    } else {
      _controlsController.reverse();
    }
  }

  void _onTapScreen() {
    if (!widget.isVideo) return;
    _setControlsVisible(!_controlsVisible);
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
          if (widget.isVideo) _scheduleHideControls();
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
    _hideControlsTimer?.cancel();
    await _callService.leaveAndUpdateStatus(
        callId: widget.callId, status: 'ended');
    if (mounted) Navigator.pop(context);
  }

  String get _durationText {
    final m = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _statusText {
    if (_remoteUid != null) return _durationText;
    if (_joined) return 'Ringing…';
    return 'Connecting…';
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulseController.dispose();
    _controlsController.dispose();
    _hideControlsTimer?.cancel();
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.isVideo ? _buildVideoCall(size) : _buildVoiceCall(),
    );
  }

  // ── VIDEO CALL ────────────────────────────────────────────────────────────
  Widget _buildVideoCall(Size size) {
    return GestureDetector(
      onTap: _onTapScreen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Remote video — full screen
          if (_remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _callService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            )
          else
            _buildWaitingScreen(),

          // PiP local video (draggable)
          if (_joined)
            _DraggablePip(
              offset: _pipOffset,
              minimized: _pipMinimized,
              screenSize: size,
              onOffsetChanged: (o) => setState(() => _pipOffset = o),
              onTap: () => setState(() => _pipMinimized = !_pipMinimized),
              child: _cameraOff
                  ? _CameraOffPip()
                  : AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _callService.engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
            ),

          // Top bar
          AnimatedBuilder(
            animation: _controlsAnim,
            builder: (_, child) => Opacity(
              opacity: _controlsAnim.value,
              child: Transform.translate(
                offset: Offset(0, (_controlsAnim.value - 1) * 40),
                child: child,
              ),
            ),
            child: _VideoTopBar(
              username: widget.friend['username'] ?? 'Unknown',
              statusText: _statusText,
              connected: _remoteUid != null,
              onBack: _endCall,
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controlsAnim,
              builder: (_, child) => Opacity(
                opacity: _controlsAnim.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _controlsAnim.value) * 80),
                  child: child,
                ),
              ),
              child: _VideoControls(
                muted: _muted,
                cameraOff: _cameraOff,
                onMute: () async {
                  setState(() => _muted = !_muted);
                  await _callService.toggleMute(_muted);
                  _setControlsVisible(true);
                },
                onCameraToggle: () async {
                  setState(() => _cameraOff = !_cameraOff);
                  await _callService.toggleCamera(_cameraOff);
                  _setControlsVisible(true);
                },
                onFlip: () {
                  _callService.switchCamera();
                  _setControlsVisible(true);
                },
                onEndCall: _endCall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    final avatarUrl = widget.friend['avatar_url'] as String?;
    final username = widget.friend['username'] as String? ?? '?';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (avatarUrl != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6),
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
              _GlowAvatar(
                avatarUrl: avatarUrl,
                username: username,
                pulseAnim: _pulseAnim,
              ),
              const SizedBox(height: 20),
              Text(username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 10),
              const _ConnectingDots(),
            ],
          ),
        ),
      ],
    );
  }

  // ── VOICE CALL ────────────────────────────────────────────────────────────
  Widget _buildVoiceCall() {
    final avatarUrl = widget.friend['avatar_url'] as String?;
    final username = widget.friend['username'] as String? ?? '?';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (avatarUrl != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.65),
              colorBlendMode: BlendMode.darken,
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0A1E),
                  Color(0xFF1A0F35),
                  Color(0xFF0A0818)
                ],
              ),
            ),
          ),
        Container(color: Colors.black.withOpacity(0.3)),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              _GlowAvatar(
                avatarUrl: avatarUrl,
                username: username,
                pulseAnim: _pulseAnim,
                size: 90,
              ),
              const SizedBox(height: 24),
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: TextStyle(
                    color: _remoteUid != null
                        ? const Color(0xFF4ADE80)
                        : Colors.white54,
                    fontSize: 15,
                    fontWeight:
                        _remoteUid != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              const Spacer(),
              _VoiceControls(
                muted: _muted,
                speakerOn: _speakerOn,
                onMute: () async {
                  setState(() => _muted = !_muted);
                  await _callService.toggleMute(_muted);
                },
                onSpeaker: () => setState(() => _speakerOn = !_speakerOn),
                onEndCall: _endCall,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
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
    final w = minimized ? 60.0 : 110.0;
    final h = minimized ? 60.0 : 160.0;

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (d) {
          final newOffset = offset + d.delta;
          final clamped = Offset(
            newOffset.dx.clamp(8, screenSize.width - w - 8),
            newOffset.dy.clamp(8, screenSize.height - h - 8),
          );
          onOffsetChanged(clamped);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(minimized ? 30 : 20),
            border:
                Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(minimized ? 30 : 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CameraOffPip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: const Center(
        child:
            Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 28),
      ),
    );
  }
}

// ── Video top bar ─────────────────────────────────────────────────────────────
class _VideoTopBar extends StatelessWidget {
  final String username;
  final String statusText;
  final bool connected;
  final VoidCallback onBack;

  const _VideoTopBar({
    required this.username,
    required this.statusText,
    required this.connected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            _GlassButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: onBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
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
                              : Colors.white60,
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
    );
  }
}

// ── Video bottom controls ─────────────────────────────────────────────────────
class _VideoControls extends StatelessWidget {
  final bool muted, cameraOff;
  final VoidCallback onMute, onCameraToggle, onFlip, onEndCall;

  const _VideoControls({
    required this.muted,
    required this.cameraOff,
    required this.onMute,
    required this.onCameraToggle,
    required this.onFlip,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _VideoCtrlBtn(
                    icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    active: muted,
                    label: muted ? 'Unmute' : 'Mute',
                    onTap: onMute,
                  ),
                  _VideoCtrlBtn(
                    icon: cameraOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    active: cameraOff,
                    label: cameraOff ? 'Cam On' : 'Cam Off',
                    onTap: onCameraToggle,
                  ),
                  _VideoCtrlBtn(
                    icon: Icons.flip_camera_ios_rounded,
                    label: 'Flip',
                    onTap: onFlip,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onEndCall,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFFEF4444).withOpacity(0.45),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded,
                              color: Colors.white, size: 26),
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
    );
  }
}

class _VideoCtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _VideoCtrlBtn({
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(active ? 0 : 0.2),
              ),
            ),
            child: Icon(icon,
                color: active ? Colors.black87 : Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
    );
  }
}

// ── Voice controls ────────────────────────────────────────────────────────────
class _VoiceControls extends StatelessWidget {
  final bool muted, speakerOn;
  final VoidCallback onMute, onSpeaker, onEndCall;

  const _VoiceControls({
    required this.muted,
    required this.speakerOn,
    required this.onMute,
    required this.onSpeaker,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _VoiceCtrlBtn(
                  icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: muted ? 'Unmute' : 'Mute',
                  active: muted,
                  onTap: onMute,
                ),
                GestureDetector(
                  onTap: onEndCall,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.call_end_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
                _VoiceCtrlBtn(
                  icon: speakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  label: speakerOn ? 'Speaker' : 'Earpiece',
                  active: speakerOn,
                  onTap: onSpeaker,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceCtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _VoiceCtrlBtn({
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
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(active ? 0 : 0.2),
              ),
            ),
            child: Icon(icon,
                color: active ? Colors.black87 : Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _GlowAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final Animation<double> pulseAnim;
  final double size;

  const _GlowAvatar({
    required this.avatarUrl,
    required this.username,
    required this.pulseAnim,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: pulseAnim.value * 1.15,
            child: Container(
              width: size * 2 + 20,
              height: size * 2 + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C56E1).withOpacity(0.08),
              ),
            ),
          ),
          Transform.scale(
            scale: pulseAnim.value,
            child: Container(
              width: size * 2 + 4,
              height: size * 2 + 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C56E1).withOpacity(0.14),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C56E1).withOpacity(0.5),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: size,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              backgroundColor: const Color(0xFF3D2270),
              child: avatarUrl == null
                  ? Text(
                      username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: size * 0.55,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
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

class _ConnectingDots extends StatefulWidget {
  const _ConnectingDots();

  @override
  State<_ConnectingDots> createState() => _ConnectingDotsState();
}

class _ConnectingDotsState extends State<_ConnectingDots>
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
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity =
                (0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2)).clamp(0.0, 1.0);
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
        );
      },
    );
  }
}
