import 'package:flutter/material.dart';

class MainButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final bool isLoading;
  final Color? buttonColor;
  final Color? textColor;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double iconGap;

  const MainButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isFullWidth = true,
    this.isLoading = false,
    this.buttonColor,
    this.textColor,
    this.leadingIcon,
    this.trailingIcon,
    this.iconGap = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final mainPurple = const Color(0xFF7C56E1);
    final theme = Theme.of(context);
    final effectiveButtonColor = buttonColor ?? mainPurple;
    final effectiveTextColor = textColor ?? Colors.white;

    Widget buildContent() {
      if (isLoading) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      }

      final hasLeading = leadingIcon != null;
      final hasTrailing = trailingIcon != null;

      if (!hasLeading && !hasTrailing) {
        return Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: effectiveTextColor,
            letterSpacing: 0.5,
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasLeading) leadingIcon!,
          if (hasLeading) SizedBox(width: iconGap),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: effectiveTextColor,
              letterSpacing: 0.5,
            ),
          ),
          if (hasTrailing) SizedBox(width: iconGap),
          if (hasTrailing) trailingIcon!,
        ],
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveButtonColor,
          foregroundColor: effectiveTextColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          shadowColor: effectiveButtonColor.withOpacity(0.3),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return effectiveTextColor.withOpacity(0.2);
            }
            if (states.contains(WidgetState.hovered)) {
              return effectiveTextColor.withOpacity(0.1);
            }
            return null;
          }),
        ),
        onPressed: isLoading ? null : onPressed,
        child: buildContent(),
      ),
    );
  }
}
