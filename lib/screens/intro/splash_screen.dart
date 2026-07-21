import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:live/auth/auth_gate.dart';
import 'package:live/screens/auth/auth_ui.dart';
import 'package:live/screens/intro/match_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Single loop drives the broadcast "signal" rings and the logo breathe.
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 3200),
    vsync: this,
  )..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _checkAuthenticationAndNavigate);
  }

  void _checkAuthenticationAndNavigate() {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            session != null ? const AuthGate() : const MatchScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // One expanding broadcast wave. t is 0..1 within its own cycle.
  Widget _signalRing(double t) {
    final scale = 0.55 + t * 1.4;
    final opacity = (0.5 * (1 - t)).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.accent,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Soft glow anchored behind the logo
            Align(
              alignment: const Alignment(0, -0.35),
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            // Hero content — intentional, generous, centered
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - v)),
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _logo(),
                    const SizedBox(height: 40),
                    _tagline(),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return SizedBox(
      width: 240,
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final p = _controller.value;
          final breathe = 1 + 0.03 * math.sin(p * 2 * math.pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              _signalRing(p),
              _signalRing((p + 0.33) % 1.0),
              _signalRing((p + 0.66) % 1.0),
              Transform.scale(scale: breathe, child: child),
            ],
          );
        },
        child: Image.asset(
          'assets/icons/live.png',
          width: 118,
          height: 118,
          color: Colors.white,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  Widget _tagline() {
    return Text(
      'Connecting people instantly',
      style: TextStyle(
        color: Colors.white.withOpacity(0.72),
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}
