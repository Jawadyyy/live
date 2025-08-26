import 'package:flutter/material.dart';

class ChatFab extends StatelessWidget {
  final Widget searchScreen;

  const ChatFab({super.key, required this.searchScreen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FloatingActionButton(
      elevation: 6,
      backgroundColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tooltip: "Search",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => searchScreen),
        );
      },
      child: Icon(
        Icons.search,
        size: 28,
        color: isDark ? Colors.black : Colors.white,
      ),
    );
  }
}
