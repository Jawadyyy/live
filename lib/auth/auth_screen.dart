import 'package:flutter/material.dart';
import 'package:live/components/primary_button.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header with logo
              Column(
                children: [
                  Icon(
                    Icons.forum_rounded,
                    color: theme.primaryColor,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'L I V E',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: theme.primaryColor,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),

              // Main content
              Column(
                children: [
                  Text(
                    'Ready to Find Your\nMatch?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Let's join and start connecting",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),

              // Auth buttons
              Column(
                children: [
                  MainButton(
                    text: 'Join',
                    onPressed: () {
                      // Handle join action
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Handle login action
                    },
                    child: Text(
                      'Already have an account',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
