import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:live/screens/agora_services/agora_call_service.dart';
import 'package:live/screens/main/chat_screen/message_screen/call_screen/call_screen.dart';
import 'package:live/screens/main/home_screen/home.dart';
import 'package:live/screens/main/chat_screen/chat.dart';
import 'package:live/screens/main/stream_screen/stream.dart';
import 'package:live/screens/main/profile_screen/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 0;
  bool _isShowingCallSheet = false; // prevents duplicate sheets

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const StreamScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    Supabase.instance.client
        .from('calls')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((calls) async {
          if (!mounted || _isShowingCallSheet) return;

          final incoming = calls
              .where((c) =>
                  c['receiver_id'] == currentUserId && c['status'] == 'ringing')
              .toList();

          if (incoming.isEmpty) return;

          final call = incoming.first;

          // Fetch caller's profile so we can show their username
          final callerProfile = await Supabase.instance.client
              .from('profiles')
              .select('username, avatar_url')
              .eq('id', call['caller_id'])
              .maybeSingle();

          if (!mounted || _isShowingCallSheet) return;

          _showIncomingCallSheet(call, callerProfile);
        });
  }

  void _showIncomingCallSheet(
    Map<String, dynamic> call,
    Map<String, dynamic>? callerProfile,
  ) {
    setState(() => _isShowingCallSheet = true);

    final username = callerProfile?['username'] ?? 'Unknown';
    final avatarUrl = callerProfile?['avatar_url'];
    final isVideo = call['call_type'] == 'video';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1040),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Call type label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    color: Colors.white60,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Incoming ${call['call_type']} call',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Avatar
            CircleAvatar(
              radius: 42,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              backgroundColor: const Color(0xFF7C56E1),
              child: avatarUrl == null
                  ? Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 14),

            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            // Decline / Accept buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline
                _callActionButton(
                  icon: Icons.call_end_rounded,
                  label: 'Decline',
                  color: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() => _isShowingCallSheet = false);
                    await AgoraCallService().declineCall(call['id']);
                  },
                ),

                // Accept
                _callActionButton(
                  icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                  label: 'Accept',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _isShowingCallSheet = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CallScreen(
                          friend: {
                            'id': call['caller_id'],
                            'username': username,
                            'avatar_url': avatarUrl,
                          },
                          channelName: call['channel_name'],
                          callId: call['id'],
                          isVideo: isVideo,
                          isIncoming: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    ).whenComplete(() {
      // Reset flag if user somehow dismisses it
      if (mounted) setState(() => _isShowingCallSheet = false);
    });
  }

  Widget _callActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChange(int index) {
    setState(() => _selectedIndex = index);
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
    const double iconSize = 24;
    const double padding = 16;

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
              padding: const EdgeInsets.symmetric(
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
                  iconPath: 'assets/icons/home.png',
                  isActive: _selectedIndex == 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  iconSize: iconSize,
                ),
                _buildTab(
                  context,
                  label: 'Chat',
                  iconPath: 'assets/icons/message.png',
                  isActive: _selectedIndex == 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  iconSize: iconSize,
                ),
                _buildTab(
                  context,
                  label: 'Stream',
                  iconPath: 'assets/icons/tv.png',
                  isActive: _selectedIndex == 2,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  iconSize: iconSize,
                ),
                _buildTab(
                  context,
                  label: 'Profile',
                  iconPath: 'assets/icons/user.png',
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
      icon: Icons.circle,
      iconSize: 0.1,
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
                color:
                    const Color.fromARGB(255, 234, 116, 255).withOpacity(0.1),
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
