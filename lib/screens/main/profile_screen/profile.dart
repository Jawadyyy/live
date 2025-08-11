import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/screens/auth/login_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final response =
        await _supabase
            .from('users')
            .select(
              'uuid,email,phone_number,username,age,dob,bio,avatar_url,created_at',
            )
            .eq('uuid', user.id)
            .single();

    if (mounted) {
      setState(() {
        _userData = response;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value.isNotEmpty ? value : 'Not provided'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userData == null
              ? const Center(child: Text('No profile data found'))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _userData!['avatar_url'] != null
                              ? NetworkImage(_userData!['avatar_url'])
                              : null,
                      child:
                          _userData!['avatar_url'] == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Username
                  Center(
                    child: Text(
                      _userData!['username'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bio
                  if ((_userData!['bio'] ?? '').isNotEmpty)
                    Center(
                      child: Text(
                        _userData!['bio'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ),

                  const Divider(height: 32),

                  // Info List
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

                  const SizedBox(height: 20),

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
    );
  }
}
