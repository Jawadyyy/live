import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/appbar.dart';
import 'package:live/screens/auth/login_screen.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class StreamScreen extends StatefulWidget {
  const StreamScreen({super.key});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  final authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Stream'),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        centerTitle: true,
        onToggleDarkMode: () async {
          final themeProvider = Provider.of<ThemeProvider>(
            context,
            listen: false,
          );
          await themeProvider.toggleTheme(!themeProvider.isDarkMode);
        },
      ),
      body: Center(child: Text("Stream")),
    );
  }
}
