import 'package:flutter/material.dart';
import 'package:live/auth/auth_gate.dart';
import 'package:live/components/primary_button.dart';
import 'package:live/components/secondary_button.dart';
import 'package:live/screens/auth/login_screen.dart';
import 'package:live/screens/auth/signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;

    // Dynamic colors
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.displayLarge?.color ?? Colors.black;
    final secondaryTextColor =
        isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7);
    const purpleColor = Color(0xFF7C56E1); // Purple color for login text

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24.0 : 32.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 40 : 80),

                      // Logo with theme-aware background
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark
                                  ? primaryColor.withOpacity(0.2)
                                  : primaryColor.withOpacity(0.1),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Icon(
                          Icons.forum_rounded,
                          color: primaryColor,
                          size: isSmallScreen ? 60 : 80,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 48),

                      // Title text
                      Column(
                        children: [
                          Text(
                            'Ready to Find Your',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: isSmallScreen ? 28 : 32,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Match?',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: isSmallScreen ? 32 : 38,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12.0 : 24.0,
                        ),
                        child: Text(
                          "Let's join and start connecting",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: isSmallScreen ? 16 : 18,
                            height: 1.5,
                            color: secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 40 : 60),

                      // Join Button
                      MainButton(
                        text: 'Join',
                        onPressed: () {
                          Feedback.forTap(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignupScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // "Already have an Account" text
                      Text(
                        'Already have an Account?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryTextColor,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),

                      // New SecondButton component with purple text
                      SecondButton(
                        text: 'Login',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        borderColor: purpleColor,
                        textColor:
                            purpleColor, // Add this parameter to your SecondButton component
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
