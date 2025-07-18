import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/appbar.dart';
import 'package:live/screens/auth/login_screen.dart';
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
  final double _avatarSize = 100.0;

  void logout() async {
    await authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final response =
        await _supabase.from('users').select().eq('id', user.id).single();

    if (mounted) {
      setState(() {
        _userData = response;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
        onSignOut: logout,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userData == null
              ? const Center(child: Text("No profile data found."))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar with gradient border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: CircleAvatar(
                        radius: _avatarSize,
                        backgroundImage:
                            _userData!['avatar_url'] != null
                                ? NetworkImage(_userData!['avatar_url'])
                                : null,
                        backgroundColor: colorScheme.surfaceVariant,
                        child:
                            _userData!['avatar_url'] == null
                                ? Icon(
                                  Icons.person,
                                  size: _avatarSize,
                                  color: colorScheme.onSurfaceVariant,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Username with animated underline
                    Column(
                      children: [
                        Text(
                          _userData!['username'] ?? 'Unknown',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        Container(
                          height: 2,
                          width: 60,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Bio with nice styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _userData!['bio'] ?? 'No bio yet',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.8),
                          fontStyle:
                              _userData!['bio'] == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          context,
                          value: '${_userData!['age'] ?? '--'}',
                          label: 'Age',
                          icon: Icons.cake,
                        ),
                        _buildStatItem(
                          context,
                          value: _formatDate(_userData!['dob']),
                          label: 'Birthday',
                          icon: Icons.date_range,
                        ),
                        _buildStatItem(
                          context,
                          value: _userData!['id'].toString().substring(0, 6),
                          label: 'ID',
                          icon: Icons.fingerprint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Section title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Personal Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.person_pin_circle,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info cards with elevation
                    _buildInfoCard(
                      context,
                      title: 'Full Name',
                      value: _userData!['full_name'] ?? 'Not provided',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Email',
                      value: _userData!['email'] ?? 'Not provided',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Member Since',
                      value: _formatDate(_userData!['created_at']),
                      icon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Location',
                      value: _userData!['location'] ?? 'Not specified',
                      icon: Icons.location_on_outlined,
                    ),

                    // Edit profile button
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        // Handle edit profile
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: colorScheme.primary.withOpacity(0.3),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withOpacity(0.1),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.surfaceVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '--';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat.yMMMd().format(parsedDate);
    } catch (_) {
      return date;
    }
  }
}
