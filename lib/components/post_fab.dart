import 'package:flutter/material.dart';

class PostFab extends StatelessWidget {
  final VoidCallback onPressed;

  const PostFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FloatingActionButton(
      heroTag: "postFab",
      elevation: 6,
      backgroundColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tooltip: "Create Post",
      onPressed: onPressed,
      child: Icon(
        Icons.add,
        size: 30,
        color: isDark ? Colors.black : Colors.white,
      ),
    );
  }
}
