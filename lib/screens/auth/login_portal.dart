import 'package:flutter/material.dart';
import 'package:live/components/primary_button.dart' show MainButton;
import 'package:live/components/secondary_button.dart';

class LoginPortal extends StatelessWidget {
  const LoginPortal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;

    final backgroundColor =
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFF7C56E1);
    final dialogColor =
        isDark
            ? const Color.fromARGB(255, 46, 39, 63)
            : const Color(0xFF5B409D);
    final purpleColor = const Color(0xFF7C56E1);
    final accentColor = isDark ? purpleColor : Colors.white;
    final lightPurple = const Color(0xFF9D7BFF);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? null
                  : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFF7C56E1), const Color(0xFF5B409D)],
                    stops: [0.0, 1.0],
                  ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: accentColor,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                    top: isSmallScreen ? 20 : 40,
                    bottom: isSmallScreen ? 30 : 50,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'L I V E',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Getting Started is Easy',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 30,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: dialogColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 25),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: MainButton(
                            text: 'Login with ID',
                            onPressed: () {},
                            buttonColor: purpleColor,
                            textColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: MainButton(
                            text: 'Login with Phone',
                            onPressed: () {},
                            buttonColor: Colors.white,
                            textColor: purpleColor,
                          ),
                        ),
                        SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: MainButton(
                            text: 'Login with Facebook',
                            onPressed: () {},
                            buttonColor: Colors.white,
                            textColor: purpleColor,
                          ),
                        ),
                        SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: MainButton(
                            text: 'Login with Google',
                            onPressed: () {},
                            buttonColor: Colors.white,
                            textColor: purpleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                    top: isSmallScreen ? 30 : 40,
                    bottom: isSmallScreen ? 30 : 40,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accentColor,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: isSmallScreen ? 300 : 340,
                        child: SecondButton(
                          text: 'Sign Up',
                          onPressed: () {},
                          borderColor: accentColor,
                          textColor: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
