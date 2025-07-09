// custom_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;
  final bool isDarkMode;

  static const List<Widget> _pageOptions = <Widget>[
    Text('Home', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
    Text(
      'Streaming',
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
    ),
    Text('Chart', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
    Text(
      'Profile',
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
    ),
  ];

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabChange,
    required this.isDarkMode,
  }) : super(key: key);

  static Widget getPageContent(int index) {
    return _pageOptions.elementAt(index);
  }

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color.fromARGB(255, 184, 158, 255);
    final Color inactiveColor = isDarkMode ? Colors.white70 : Colors.black54;
    final Color tabBackgroundColor =
        isDarkMode ? Colors.grey[800]!.withOpacity(0.7) : Colors.grey[100]!;
    final Color backgroundColor =
        isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            hoverColor: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
            gap: 8,
            activeColor: activeColor, // Use your primary color here
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: tabBackgroundColor,
            color: inactiveColor,
            tabs: [
              GButton(
                icon: LineIcons.home,
                text: 'Home',
                textColor: activeColor, // Active text color
              ),
              GButton(
                icon: LineIcons.video,
                text: 'Streaming',
                textColor: activeColor,
              ),
              GButton(
                icon: LineIcons.barChart,
                text: 'Chart',
                textColor: activeColor,
              ),
              GButton(
                icon: LineIcons.user,
                text: 'Profile',
                textColor: activeColor,
              ),
            ],
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
            // Add curve for smooth animation
            curve: Curves.easeInOut,
            // Optional: Add haptic feedback
            haptic: true,
          ),
        ),
      ),
    );
  }
}
