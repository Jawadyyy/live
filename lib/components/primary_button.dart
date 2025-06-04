import 'package:flutter/material.dart';

class MainButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;

  const MainButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: theme.elevatedButtonTheme.style?.copyWith(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          elevation: WidgetStateProperty.all(4),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            final baseColor =
                theme.elevatedButtonTheme.style?.backgroundColor?.resolve(
                  states,
                ) ??
                theme.colorScheme.primary;
            return Color.alphaBlend(Colors.white.withOpacity(0.2), baseColor);
          }),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color:
                isDark
                    ? theme.elevatedButtonTheme.style?.foregroundColor?.resolve(
                      {WidgetState.selected},
                    )
                    : theme.elevatedButtonTheme.style?.foregroundColor?.resolve(
                      {WidgetState.selected},
                    ),
          ),
        ),
      ),
    );
  }
}
