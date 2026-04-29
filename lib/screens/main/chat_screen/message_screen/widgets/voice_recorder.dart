import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorder extends StatefulWidget {
  final Function(String filePath, int durationSeconds) onSend;
  final VoidCallback onCancel;

  const VoiceRecorder({
    super.key,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  int _seconds = 0;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      widget.onCancel();
      return;
    }
    await _recorder.openRecorder();
    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(toFile: _filePath, codec: Codec.aacADTS);
    setState(() => _isRecording = true);

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return false;
      setState(() => _seconds++);
      return true;
    });
  }

  Future<void> _stopAndSend() async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    setState(() => _isRecording = false);
    if (_filePath != null && _seconds > 0) {
      widget.onSend(_filePath!, _seconds);
    } else {
      widget.onCancel();
    }
  }

  Future<void> _cancel() async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    setState(() => _isRecording = false);
    widget.onCancel();
  }

  String get _timeLabel {
    final m = (_seconds ~/ 60).toString();
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    if (_isRecording) {
      _recorder.stopRecorder();
      _recorder.closeRecorder();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          // Cancel
          GestureDetector(
            onTap: _cancel,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Recording indicator + timer
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                _PulsingDot(color: Colors.red),
                const SizedBox(width: 10),
                Text(
                  'Recording  $_timeLabel',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(width: 12),

          // Send
          GestureDetector(
            onTap: _stopAndSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _anim = Tween(begin: 0.35, end: 1.0).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
