import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/text_field.dart';
import 'package:live/screens/auth/login_screen.dart';
import 'package:live/screens/auth/otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final Color brandColor = const Color(0xFF7C56E1);

  Future<void> sendResetLink() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      //await authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally navigate back after successful submission
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width > 600 ? size.width * 0.2 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Brand Header
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum, color: brandColor, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Forgot Password',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email to receive a reset link',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              // Email Field
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 32),

              // Send Reset Link Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            if (_emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter your email address',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() => _isLoading = true);

                            try {
                              // Send OTP to email
                              final otp = await authService.sendOtp(
                                _emailController.text.trim(),
                              );

                              // For testing purposes, show the OTP in console
                              debugPrint(
                                'OTP for ${_emailController.text}: $otp',
                              );

                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => OtpVerificationScreen(
                                          email: _emailController.text.trim(),
                                        ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: ${e.toString()}"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: brandColor,
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 24),

              // Back to Login
              Center(
                child: TextButton(
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      ),
                  child: RichText(
                    text: TextSpan(
                      text: 'Remember your password? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: brandColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
