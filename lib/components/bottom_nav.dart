import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:live/screens/main/home.dart';
import 'package:live/screens/main/chat.dart';
import 'package:live/screens/main/stream.dart';
import 'package:live/screens/main/profile.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const StreamScreen(),
    const ProfileScreen(),
  ];

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final Color activeColor = theme.colorScheme.secondary;
    final Color inactiveColor = theme.unselectedWidgetColor;
    final Color backgroundColor =
        theme.bottomNavigationBarTheme.backgroundColor ??
        (isDarkMode ? const Color(0xFF121212) : Colors.white);
    final double iconSize = 24;
    final double padding = 16;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              spreadRadius: 1,
              color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: GNav(
              rippleColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              hoverColor: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
              gap: 10,
              activeColor: activeColor,
              iconSize: iconSize,
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding,
              ),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.transparent,
              color: inactiveColor,
              selectedIndex: _selectedIndex,
              onTabChange: _onTabChange,
              curve: Curves.easeOutExpo,
              haptic: true,
              tabs: [
                _buildTab(
                  context,
                  label: 'Home',
                  iconPath: 'icons/home.png',
                  isActive: _selectedIndex == 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  iconSize: iconSize,
                ),
                _buildTab(
                  context,
                  label: 'Chat',
                  iconPath: 'icons/message.png',
                  isActive: _selectedIndex == 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  iconSize: iconSize,
                ),
                _buildTab(
                  context,
                  label: 'Stream',
                  iconPath: 'icons/tv.png',
                  isActive: _selectedIndex == 2,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  iconSize: iconSize,
                ),
                _buildTab(
                  context,
                  label: 'Profile',
                  iconPath: 'icons/user.png',
                  isActive: _selectedIndex == 3,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  iconSize: iconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  GButton _buildTab(
    BuildContext context, {
    required String label,
    required String iconPath,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required double iconSize,
  }) {
    return GButton(
      icon: Icons.circle, // This is a placeholder, we won't actually use it
      iconSize: 0.1, // Make the placeholder icon very small
      text: label,
      textStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: isActive ? activeColor : inactiveColor,
      ),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          if (isActive)
            Container(
              width: iconSize * 1.8,
              height: iconSize * 1.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(
                  255,
                  234,
                  116,
                  255,
                ).withOpacity(0.1),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
            ),
            child: Image.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
