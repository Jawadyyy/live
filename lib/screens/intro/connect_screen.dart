import 'package:flutter/material.dart';
import 'package:live/components/primary_button.dart';
import 'package:live/screens/auth/auth_screen.dart';

class ConnectScreen extends StatelessWidget {
  final VoidCallback? onContinuePressed;

  const ConnectScreen({super.key, this.onContinuePressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 24.0,
                    vertical: isSmallScreen ? 12.0 : 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App logo/header
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.forum_rounded,
                              color: theme.primaryColor,
                              size: isSmallScreen ? 28 : 34,
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Text(
                              'L I V E',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: isSmallScreen ? 26 : 30,
                                fontWeight: FontWeight.w900,
                                color: theme.primaryColor,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Image with glow effect
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height:
                                  isLargeScreen
                                      ? 320
                                      : (isSmallScreen ? 240 : 280),
                              width:
                                  isLargeScreen
                                      ? 320
                                      : (isSmallScreen ? 240 : 280),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.3),
                                    blurRadius: 50,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height:
                                  isLargeScreen
                                      ? 260
                                      : (isSmallScreen ? 180 : 220),
                              width:
                                  isLargeScreen
                                      ? 260
                                      : (isSmallScreen ? 180 : 220),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'images/connect.png',
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.person_add_alt_1_rounded,
                                        size: isSmallScreen ? 60 : 90,
                                        color: theme.primaryColor.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 40),

                      // Content section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show Your True Self',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize:
                                  isLargeScreen
                                      ? 42
                                      : (isSmallScreen ? 30 : 38),
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              color: theme.textTheme.displayLarge?.color,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 20),
                          RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: isSmallScreen ? 15 : 17,
                                height: 1.6,
                                color: theme.textTheme.bodyLarge?.color
                                    ?.withOpacity(0.85),
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Upload your best photos and write a bio that\n',
                                ),
                                const TextSpan(text: 'reflects who you are. '),
                                TextSpan(
                                  text:
                                      'Be genuine and let your\npersonality shine!',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 40),

                      // Page indicators
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isSmallScreen ? 10 : 12,
                              height: isSmallScreen ? 10 : 12,
                              margin: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            Container(
                              width: isSmallScreen ? 10 : 12,
                              height: isSmallScreen ? 10 : 12,
                              margin: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Button
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 80 : 0,
                          ),
                          child: MainButton(
                            text: 'Next',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AuthScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
