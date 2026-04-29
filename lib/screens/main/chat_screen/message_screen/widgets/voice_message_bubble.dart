import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final bool isMe;
  final ColorScheme colors;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    required this.isMe,
    required this.colors,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isInitialized = false;
  double _progress = 0;
  int _currentSeconds = 0;

  static const List<double> _waveHeights = [
    0.2,
    0.4,
    0.6,
    0.9,
    0.7,
    1.0,
    0.75,
    0.5,
    0.85,
    0.6,
    0.3,
    0.7,
    0.5,
    0.95,
    0.8,
    0.55,
    1.0,
    0.4,
    0.75,
    0.6,
    0.25,
    0.8,
    0.65,
    0.9,
    0.45,
    0.7,
    0.3,
    0.55,
    0.85,
    0.65,
    0.4,
    0.95,
    0.75,
    0.5,
    0.3,
    0.88,
    0.6,
    0.8,
    0.45,
    0.7,
  ];

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pausePlayer();
      setState(() => _isPlaying = false);
    } else {
      await _player.startPlayer(
        fromURI: widget.audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _progress = 0;
              _currentSeconds = 0;
            });
          }
        },
      );
      await _player.setSubscriptionDuration(const Duration(milliseconds: 80));
      _player.onProgress!.listen((e) {
        if (!mounted) return;
        final total = e.duration.inMilliseconds;
        final pos = e.position.inMilliseconds;
        setState(() {
          _progress = total > 0 ? pos / total : 0;
          _currentSeconds = e.position.inSeconds;
        });
      });
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : widget.colors.primary;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isMe
              ? widget.colors.primary
              : widget.colors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(widget.isMe ? 22 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 22),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isInitialized ? _togglePlay : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _IGWaveform(
                  progress: _progress,
                  heights: _waveHeights,
                  activeColor: color,
                  inactiveColor: color.withOpacity(0.25),
                  width: 140,
                ),
                const SizedBox(height: 5),
                Text(
                  _isPlaying
                      ? _formatDuration(_currentSeconds)
                      : _formatDuration(widget.durationSeconds),
                  style: TextStyle(
                    color: color.withOpacity(0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.mic_rounded,
              color: color.withOpacity(0.5),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

class _IGWaveform extends StatelessWidget {
  final double progress;
  final List<double> heights;
  final Color activeColor;
  final Color inactiveColor;
  final double width;

  const _IGWaveform({
    required this.progress,
    required this.heights,
    required this.activeColor,
    required this.inactiveColor,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    const double maxBarHeight = 28;
    final double totalSpacing = (heights.length - 1) * 2;
    final double barWidth = (width - totalSpacing) / heights.length;

    return SizedBox(
      width: width,
      height: maxBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(heights.length, (i) {
          final played = i / heights.length <= progress;
          final barHeight =
              (heights[i] * maxBarHeight).clamp(4.0, maxBarHeight);

          return Padding(
            padding: EdgeInsets.only(
              right: i < heights.length - 1 ? 2 : 0,
            ),
            child: Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: played ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
