import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/text_field.dart';
import 'package:live/screens/auth/pass_reset_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String generatedOtp; // ✅ Add this
  final AuthService authService = AuthService();

  OtpVerificationScreen({
    super.key,
    required this.email,
    required this.generatedOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  final Color brandColor = const Color(0xFF7C56E1);

  @override
  void initState() {
    super.initState();
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

  void verifyOtp() async {
    setState(() {
      _isLoading = true;
    });

    final enteredOtp = _otpControllers.map((c) => c.text.trim()).join();

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isLoading = false;
    });

    if (enteredOtp == widget.generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified successfully!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PasswordResetScreen(email: widget.email),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
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
                      // Optional: resend logic here
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : verifyOtp,
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
                          : const Text(
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
