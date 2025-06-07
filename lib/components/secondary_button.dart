import 'package:flutter/material.dart';

class SecondButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final bool isLoading;
  final Color borderColor;
  final double borderWidth;
  final Color? textColor;

  const SecondButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isFullWidth = true,
    this.isLoading = false,
    this.borderColor = const Color(0xFF7C56E1),
    this.borderWidth = 2.0,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedTextColor =
        textColor ?? (isDark ? Colors.white : Colors.black);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: borderColor,
          side: BorderSide(color: borderColor, width: borderWidth),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: Colors.transparent,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return borderColor.withOpacity(0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return borderColor.withOpacity(0.05);
            }
            return null;
          }),
        ),
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: borderColor,
                  ),
                )
                : Text(
                  text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: resolvedTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
      ),
    );
  }
}
