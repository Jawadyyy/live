import 'package:flutter/material.dart';
import 'package:live/components/text_field.dart';
import 'package:live/screens/auth/pass_reset_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  final Color brandColor = const Color(0xFF7C56E1);

  @override
  void initState() {
    super.initState();
    // Auto-focus the first OTP field when screen loads
    _otpFocusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleOtpInput(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index].unfocus();
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index].unfocus();
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> verifyOtp() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement your OTP verification logic here
    try {
      // await authService.verifyOtp(widget.email, otpCode);
      // Navigate to success screen or new password screen
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
                'OTP Verification',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  text: 'Enter the 6-digit code sent to ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: brandColor, width: 2),
                        ),
                      ),
                      onChanged: (value) => _handleOtpInput(index, value),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement resend OTP logic
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Resend',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            final otpCode =
                                _otpControllers.map((c) => c.text).join();
                            if (otpCode.length != 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter complete 6-digit code',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() => _isLoading = true);

                            try {
                              // Replace with your actual OTP verification logic
                              // await authService.verifyOtp(widget.email, otpCode);

                              // On successful verification, navigate to PasswordResetScreen
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PasswordResetScreen(
                                          email: widget.email,
                                          otpCode:
                                              otpCode, // Pass the OTP if needed for verification
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
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : Text(
                            'Verify',
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Login',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
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
