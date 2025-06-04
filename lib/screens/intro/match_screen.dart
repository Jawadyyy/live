import 'package:flutter/material.dart';
import 'package:live/components/primary_button.dart';
import 'package:live/screens/intro/connect_screen.dart';

class MatchScreen extends StatelessWidget {
  final bool isActivePage;

  const MatchScreen({super.key, this.isActivePage = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 24.0,
                    vertical: isSmallScreen ? 12.0 : 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Header
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

                      // Image with Glow
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
                                  'images/chatting.png',
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.image_not_supported,
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

                      // Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Your Chat Partner',
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
                          Text(
                            'Meaningful connections start here. Whether for friendship, '
                            'shared interests, or just someone to chat with - you\'re in '
                            'the right place.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: isSmallScreen ? 15 : 17,
                              height: 1.6,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),

                      // Flexible space between content and bottom widgets
                      Expanded(child: SizedBox.shrink()),

                      // Page Indicators
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
                                color:
                                    isActivePage
                                        ? theme.primaryColor
                                        : theme.primaryColor.withOpacity(0.3),
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
                                color:
                                    !isActivePage
                                        ? theme.primaryColor
                                        : theme.primaryColor.withOpacity(0.3),
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
                                  builder: (context) => const ConnectScreen(),
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
            ),
          );
        },
      ),
    );
  }
}
