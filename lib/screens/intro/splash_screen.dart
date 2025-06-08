import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:live/screens/intro/match_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Improved animation curves and timing
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFF6B46E1),
      end: const Color(0xFF7C56E1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MatchScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPulsingDot(double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulseValue =
            0.8 + 0.2 * math.sin(_controller.value * math.pi * 4);
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _colorAnimation.value,
          body: Stack(
            children: [
              // Background glow effect
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.5,
                          colors: [
                            Colors.white.withOpacity(
                              0.1 * _glowAnimation.value,
                            ),
                            _colorAnimation.value!.withOpacity(0.01),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple effect
                        if (_rippleAnimation.value > 0)
                          Transform.scale(
                            scale: _rippleAnimation.value * 1.5,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(
                                  0.2 * (1 - _rippleAnimation.value),
                                ),
                              ),
                            ),
                          ),

                        // Main icon with scaling
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                return RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.8,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.7),
                                  ],
                                  stops: const [0.0, 1.0],
                                ).createShader(bounds);
                              },
                              child: const Icon(
                                Icons.forum_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // App title with improved typography
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'L I V E',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle with slide animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        'Connecting people instantly',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Pulsing dots loader with improved timing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPulsingDot(12),
                        const SizedBox(width: 8),
                        _buildPulsingDot(12),
                        const SizedBox(width: 8),
                        _buildPulsingDot(12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
