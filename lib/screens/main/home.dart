// home.dart
import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/bottom_nav.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  int _selectedIndex = 0;

  void logout() async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: logout,
            icon: Icon(
              Icons.logout,
              color: isDarkMode ? Colors.white : const Color(0xFF7C56E1),
            ),
          ),
        ],
      ),
      body: Center(child: CustomBottomNavBar.getPageContent(_selectedIndex)),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        isDarkMode: isDarkMode,
      ),
    );
  }
}
