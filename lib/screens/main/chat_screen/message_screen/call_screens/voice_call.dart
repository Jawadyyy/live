import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:live/screens/agora_services/agora_call_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceCallScreen extends StatefulWidget {
  final Map<String, dynamic> friend;
  final String channelName;
  final String callId;
  final bool isIncoming;

  const VoiceCallScreen({
    super.key,
    required this.friend,
    required this.channelName,
    required this.callId,
    this.isIncoming = false,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  final _callService = AgoraCallService();
  int? _remoteUid;
  bool _muted = false, _speakerOn = true, _joined = false, _callEnded = false;

  final _stopwatch = Stopwatch();
  Duration _callDuration = Duration.zero;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

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
        isVideo: false,
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

  String get _statusText {
    if (_remoteUid != null) {
      final m =
          _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s =
          _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    if (_joined) return 'Ringing…';
    return 'Connecting…';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.friend['avatar_url'] as String?;
    final username = widget.friend['username'] as String? ?? '?';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred avatar background
          if (avatarUrl != null)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
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
                  colors: [
                    Color(0xFF0F0A1E),
                    Color(0xFF1A0F35),
                    Color(0xFF0A0818),
                  ],
                ),
              ),
            ),

          // Dark scrim
          Container(color: Colors.black.withOpacity(0.35)),

          // Content
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 56),

                  // Avatar with pulse rings
                  _PulseAvatar(
                    avatarUrl: avatarUrl,
                    username: username,
                    pulseAnim: _pulseAnim,
                    isActive: _remoteUid != null,
                  ),

                  const SizedBox(height: 28),

                  // Name
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Status
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Row(
                      key: ValueKey(_statusText),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_remoteUid != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        Text(
                          _statusText,
                          style: TextStyle(
                            color: _remoteUid != null
                                ? const Color(0xFF4ADE80)
                                : Colors.white54,
                            fontSize: 16,
                            fontWeight: _remoteUid != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Controls
                  _VoiceControlsPanel(
                    muted: _muted,
                    speakerOn: _speakerOn,
                    onMute: () async {
                      setState(() => _muted = !_muted);
                      await _callService.toggleMute(_muted);
                    },
                    onSpeaker: () => setState(() => _speakerOn = !_speakerOn),
                    onEndCall: _endCall,
                  ),

                  const SizedBox(height: 52),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulse Avatar ──────────────────────────────────────────────────────────────
class _PulseAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final Animation<double> pulseAnim;
  final bool isActive;

  const _PulseAvatar({
    required this.avatarUrl,
    required this.username,
    required this.pulseAnim,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Transform.scale(
              scale: pulseAnim.value * 1.12,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isActive
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF7C56E1))
                      .withOpacity(0.07),
                ),
              ),
            ),
            // Mid pulse ring
            Transform.scale(
              scale: pulseAnim.value,
              child: Container(
                width: 185,
                height: 185,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isActive
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF7C56E1))
                      .withOpacity(0.12),
                ),
              ),
            ),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isActive
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF7C56E1))
                        .withOpacity(0.4),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 76,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                backgroundColor: const Color(0xFF3D2270),
                child: avatarUrl == null
                    ? Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 52,
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

// ── Voice Controls Panel ──────────────────────────────────────────────────────
class _VoiceControlsPanel extends StatelessWidget {
  final bool muted, speakerOn;
  final VoidCallback onMute, onSpeaker, onEndCall;

  const _VoiceControlsPanel({
    required this.muted,
    required this.speakerOn,
    required this.onMute,
    required this.onSpeaker,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withOpacity(0.13)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CtrlButton(
                  icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: muted ? 'Unmute' : 'Mute',
                  active: muted,
                  onTap: onMute,
                ),

                // End call — centre, bigger
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onEndCall,
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.55),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'End Call',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),

                _CtrlButton(
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

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CtrlButton({
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.92)
                  : Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(active ? 0 : 0.22),
              ),
            ),
            child: Icon(
              icon,
              color: active ? Colors.black87 : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
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
