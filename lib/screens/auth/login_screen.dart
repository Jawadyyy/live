import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/bottom_nav.dart';
import 'package:live/screens/auth/auth_ui.dart';
import 'package:live/screens/auth/forgot_pass_screen.dart';
import 'package:live/screens/auth/signup_screen.dart';
import 'package:live/screens/main/profile_screen/profile_setup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _goToApp(Map<String, dynamic>? profile) {
    final destination =
        (profile != null && profile['is_profile_complete'] == false)
            ? const ProfileSetupScreen()
            : const CustomBottomNavBar();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => destination),
      (route) => false,
    );
  }

  Future<void> login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.session != null && mounted) {
        final profile = await authService.fetchUserProfile();
        if (mounted) _goToApp(profile);
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

  Future<void> _googleLogin() async {
    final success = await authService.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      final profile = await authService.fetchUserProfile();
      if (mounted) _goToApp(profile);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AuthColors.sheet,
      body: Column(
        children: [
          // Hero gradient — extends toward the middle of the screen
          Container(
            height: size.height * 0.30,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: kHeroGradient),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.30),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthLogo(),
                        const SizedBox(height: 22),
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log in to continue to your account',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sheet — pulled up so its rounded top curves over the gradient
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: _buildSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AuthColors.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        border: Border(top: BorderSide(color: AuthColors.fieldBorder)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              controller: _emailController,
              hint: 'Email address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            AuthField(
              controller: _passwordController,
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AuthColors.muted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AuthColors.accentLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: 'Log in',
              loading: _isLoading,
              onPressed: login,
            ),
            const SizedBox(height: 18),
            const AuthOrDivider(),
            const SizedBox(height: 18),
            AuthOutlineButton(
              label: 'Continue with Google',
              onPressed: _googleLogin,
              leading: Image.asset(
                'assets/icons/google.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.g_mobiledata, color: Colors.white),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                ),
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: AuthColors.muted2, fontSize: 13.5),
                    children: [
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                          color: AuthColors.accentLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
