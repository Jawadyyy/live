import 'package:flutter/material.dart';
import 'package:live/auth/auth_gate.dart';
import 'package:live/screens/intro/connect_screen.dart';
import 'package:live/screens/intro/onboarding_page.dart';

class MatchScreen extends StatelessWidget {
  final bool isActivePage;

  const MatchScreen({super.key, this.isActivePage = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingPage(
      image: 'assets/images/chatting.png',
      fallbackIcon: Icons.image_not_supported,
      title: 'Connect &\nChat Live',
      currentPage: 0,
      onNext: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ConnectScreen()),
      ),
      onSkip: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      ),
      description: Text(
        'Join real-time conversations, share your thoughts, or stream live. '
        'Meet people from around the world who share your interests — all in one place.',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.6,
          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
        ),
      ),
    );
  }
}
