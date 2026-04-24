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
      onPressed: () async {
        final status = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const CreateStreamScreen()),
        );
        if (status != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              status == 'live'
                  ? '🔴 You are now live!'
                  : '📅 Stream scheduled!',
            ),
            backgroundColor:
                status == 'live' ? Colors.red : const Color(0xFF7C56E1),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      },
      child:
          Icon(Icons.tv, size: 30, color: isDark ? Colors.black : Colors.white),
    );
  }
}
