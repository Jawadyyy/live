import 'package:flutter/material.dart';
import 'package:live/screens/main/stream_screen/create_stream_screen.dart';

class StreamFab extends StatelessWidget {
  const StreamFab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FloatingActionButton(
      heroTag: "streamFab",
      elevation: 6,
      backgroundColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tooltip: "Create Stream",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateStreamScreen()),
        );
      },
      child: Icon(
        Icons.tv,
        size: 30,
        color: isDark ? Colors.black : Colors.white,
      ),
    );
  }
}
