import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/appbar.dart';
import 'package:live/screens/intro/splash_screen.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _friendsCount = 0; // 🔹 New variable

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void logout() async {
    await authService.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch user profile
      final response =
          await _supabase
              .from('users')
              .select(
                'id,email,phone_number,username,age,dob,bio,avatar_url,created_at',
              )
              .eq('id', user.id)
              .maybeSingle();

      // 🔹 Count friends
      final res = await _supabase
          .from('friendships')
          .select('id') // selecting at least one column
          .or('requester_id.eq.${user.id},addressee_id.eq.${user.id}')
          .eq('status', 'accepted')
          .count(
            CountOption.exact,
          ); // CountOption is available from supabase_flutter

      final totalFriends = res.count ?? 0;

      if (!mounted) return;
      setState(() {
        _userData = response;
        _friendsCount = totalFriends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _userData = null;
        _friendsCount = 0;
      });
      debugPrint('Error fetching user data: $e');
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '--';
    try {
      return DateFormat.yMMMd().format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        subtitle: Text(
          value.isNotEmpty ? value : 'Not provided',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Column(
                      children: [
                        _themeOption(
                          context,
                          'Light',
                          ThemeMode.light,
                          themeProvider.themeMode,
                          Icons.light_mode,
                          () {
                            themeProvider.setThemeMode(ThemeMode.light);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 12),
                        _themeOption(
                          context,
                          'Dark',
                          ThemeMode.dark,
                          themeProvider.themeMode,
                          Icons.dark_mode,
                          () {
                            themeProvider.setThemeMode(ThemeMode.dark);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 12),
                        _themeOption(
                          context,
                          'System',
                          ThemeMode.system,
                          themeProvider.themeMode,
                          Icons.phone_iphone,
                          () {
                            themeProvider.setThemeMode(ThemeMode.system);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _themeOption(
    BuildContext context,
    String title,
    ThemeMode value,
    ThemeMode groupValue,
    IconData icon,
    VoidCallback onTap,
  ) {
    final bool isSelected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primary.withOpacity(0.1)
                  : colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border:
              isSelected
                  ? Border.all(color: colorScheme.primary, width: 1.5)
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Profile'),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userData == null
              ? const Center(child: Text('No profile data found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Header
                    Column(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    _userData!['avatar_url'] != null
                                        ? Image.network(
                                          _userData!['avatar_url'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Icon(
                                              Icons.person,
                                              size: 60,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.5),
                                            );
                                          },
                                        )
                                        : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Username
                        Text(
                          _userData!['username'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Bio
                        if ((_userData!['bio'] ?? '').isNotEmpty)
                          Text(
                            _userData!['bio'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info List
                    _infoTile(
                      'Total Friends',
                      _friendsCount.toString(),
                      Icons.group,
                    ),
                    _infoTile('Email', _userData!['email'] ?? '', Icons.email),
                    _infoTile(
                      'Phone',
                      _userData!['phone_number'] ?? '',
                      Icons.phone,
                    ),
                    _infoTile(
                      'Age',
                      _userData!['age'] != null
                          ? _userData!['age'].toString()
                          : '',
                      Icons.cake,
                    ),
                    _infoTile(
                      'Date of Birth',
                      _formatDate(_userData!['dob']),
                      Icons.calendar_today,
                    ),
                    _infoTile(
                      'Member Since',
                      _formatDate(_userData!['created_at']),
                      Icons.access_time,
                    ),

                    // Appearance Section
                    GestureDetector(
                      onTap: () => _showThemeDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.palette,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Appearance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Consumer<ThemeProvider>(
                                    builder: (context, themeProvider, child) {
                                      String currentTheme = 'System';
                                      if (themeProvider.themeMode ==
                                          ThemeMode.light) {
                                        currentTheme = 'Light';
                                      } else if (themeProvider.themeMode ==
                                          ThemeMode.dark) {
                                        currentTheme = 'Dark';
                                      }
                                      return Text(
                                        currentTheme,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text('Log Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.onErrorContainer,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
