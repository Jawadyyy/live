import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  static const List<Widget> _pageOptions = <Widget>[
    Text('Home', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
    Text('Chat', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
    Text('Stream', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
    Text(
      'Profile',
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
    ),
  ];

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabChange,
  }) : super(key: key);

  static Widget getPageContent(int index) {
    return _pageOptions.elementAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Colors from theme
    final Color activeColor = theme.colorScheme.secondary;
    final Color inactiveColor = theme.unselectedWidgetColor;
    final Color backgroundColor =
        theme.bottomNavigationBarTheme.backgroundColor ??
        (isDarkMode ? const Color(0xFF121212) : Colors.white);
    final double iconSize = 24;
    final double padding = 16;

    return Container(
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
            tabs: [
              _buildTab(
                context,
                label: 'Home',
                iconPath: 'icons/home.png',
                isActive: selectedIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                iconSize: iconSize,
              ),
              _buildTab(
                context,
                label: 'Chat',
                iconPath: 'icons/message.png',
                isActive: selectedIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                iconSize: iconSize,
              ),
              _buildTab(
                context,
                label: 'Stream',
                iconPath: 'icons/tv.png',
                isActive: selectedIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                iconSize: iconSize,
              ),
              _buildTab(
                context,
                label: 'Profile',
                iconPath: 'icons/user.png',
                isActive: selectedIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                iconSize: iconSize,
              ),
            ],
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
            curve: Curves.easeOutExpo,
            haptic: true,
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
      icon: Icons.circle, // Required but won't be visible
      iconSize: 0.1, // Make it nearly invisible
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
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      234,
                      116,
                      255,
                    ).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      234,
                      116,
                      255,
                    ).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
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
