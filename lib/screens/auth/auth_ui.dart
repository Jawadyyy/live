import 'package:flutter/material.dart';

/// Shared visual language for the branded auth + splash screens.
///
/// These screens are intentionally dark/immersive regardless of the app's
/// light/dark theme — the accent matches AppTheme's main color 0xFF7C56E1.
class AuthColors {
  static const accent = Color(0xFF7C56E1); // app main color
  static const accentLight = Color(0xFFA88CF0);
  static const pink = Color(0xFFFF5D9E);
  static const heroMid = Color(0xFF6A34D8);
  static const heroDeep = Color(0xFF3F1C9E);
  static const logoEnd = Color(0xFF5A2FD0);
  static const bg = Color(0xFF08060F);
  static const sheet = Color(0xFF0C0A14);
  static const field = Color(0xFF15111F);
  static const fieldBorder = Color(0xFF241D38);
  static const divider = Color(0xFF221C33);
  static const muted = Color(0xFF75718A);
  static const muted2 = Color(0xFF8F8BA0);
  static const text = Color(0xFFECEAF2);
}

const double kAuthRadius = 18;

const LinearGradient kHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AuthColors.accent, AuthColors.heroMid, AuthColors.heroDeep],
);

const LinearGradient kButtonGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AuthColors.accentLight, AuthColors.accent],
);

/// LIVE wordmark used across auth screens.
class AuthLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  const AuthLogo({super.key, this.iconSize = 27, this.fontSize = 19});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.forum_rounded, color: Colors.white, size: iconSize),
        const SizedBox(width: 8),
        Text(
          'LIVE',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// Dark, filled input matching the imported LIVE design.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAuthRadius),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: AuthColors.accentLight,
      style: const TextStyle(color: AuthColors.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AuthColors.muted, fontSize: 15),
        filled: true,
        fillColor: AuthColors.field,
        prefixIcon: Icon(icon, color: AuthColors.muted, size: 20),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: border(AuthColors.fieldBorder),
        focusedBorder: border(AuthColors.accent),
        errorBorder: border(const Color(0xFFFF5D9E)),
        focusedErrorBorder: border(const Color(0xFFFF5D9E)),
      ),
    );
  }
}

/// Gradient pill button with trailing arrow + loading state.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData trailingIcon;
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.trailingIcon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kAuthRadius),
        onTap: loading ? null : onPressed,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: kButtonGradient,
            borderRadius: BorderRadius.circular(kAuthRadius),
            boxShadow: [
              BoxShadow(
                color: AuthColors.accent.withOpacity(0.45),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(trailingIcon, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Dark outlined secondary button (e.g. Google sign-in).
class AuthOutlineButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final VoidCallback? onPressed;
  const AuthOutlineButton({
    super.key,
    required this.label,
    required this.leading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AuthColors.field,
      borderRadius: BorderRadius.circular(kAuthRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kAuthRadius),
        onTap: onPressed,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kAuthRadius),
            border: Border.all(color: AuthColors.fieldBorder, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AuthColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "or" divider used between primary and social buttons.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              color: AuthColors.muted.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AuthColors.divider)),
      ],
    );
  }
}
