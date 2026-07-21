import 'package:flutter/material.dart';
import 'package:live/auth/auth_gate.dart';
import 'package:live/screens/intro/onboarding_page.dart';

class ConnectScreen extends StatelessWidget {
  final VoidCallback? onContinuePressed;

  const ConnectScreen({super.key, this.onContinuePressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingPage(
      image: 'assets/images/connect.png',
      fallbackIcon: Icons.person_add_alt_1_rounded,
      title: 'Express\nYourself',
      currentPage: 1,
      nextLabel: 'Get Started',
      onNext: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      ),
      description: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.6,
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
          ),
          children: const [
            TextSpan(
              text:
                  'Share your moments, ideas, and creativity with the community. ',
            ),
            TextSpan(
              text: 'Let your unique voice and style stand out!',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
