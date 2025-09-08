import 'package:flutter/material.dart';
import 'package:live/screens/main/post_screen/create_post_screen.dart';

class PostFab extends StatelessWidget {
  const PostFab({super.key});

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
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        );
      },
      child: Icon(
        Icons.add,
        size: 30,
        color: isDark ? Colors.black : Colors.white,
      ),
    );
  }
}
