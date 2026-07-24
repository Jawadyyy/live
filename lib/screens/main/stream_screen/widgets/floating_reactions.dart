import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Emoji that rise and fade over the video, IG/Twitch-live style.
/// Feed it a stream of emoji strings (from broadcast + local taps).
class FloatingReactions extends StatefulWidget {
  final Stream<String> reactions;
  const FloatingReactions({super.key, required this.reactions});

  @override
  State<FloatingReactions> createState() => _FloatingReactionsState();
}

class _FloatingReactionsState extends State<FloatingReactions> {
  final _active = <Widget>[];
  StreamSubscription<String>? _sub;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _sub = widget.reactions.listen(_spawn);
  }

  void _spawn(String emoji) {
    if (!mounted) return;
    final key = UniqueKey();
    final startX = 4.0 + _rng.nextDouble() * 28; // jitter near the right edge
    late final Widget w;
    w = _RisingEmoji(
      key: key,
      emoji: emoji,
      rightOffset: startX,
      drift: (_rng.nextDouble() - 0.5) * 60,
      onDone: () {
        if (mounted) setState(() => _active.remove(w));
      },
    );
    setState(() => _active.add(w));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: Stack(children: _active));
  }
}

class _RisingEmoji extends StatefulWidget {
  final String emoji;
  final double rightOffset;
  final double drift;
  final VoidCallback onDone;
  const _RisingEmoji({
    super.key,
    required this.emoji,
    required this.rightOffset,
    required this.drift,
    required this.onDone,
  });

  @override
  State<_RisingEmoji> createState() => _RisingEmojiState();
}

class _RisingEmojiState extends State<_RisingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 2200),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Positioned(
          right: widget.rightOffset + widget.drift * t,
          bottom: 90 + 260 * t,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.7 + 0.5 * sin(t * pi), // pop in, shrink out
              child: Text(widget.emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
        );
      },
    );
  }
}
