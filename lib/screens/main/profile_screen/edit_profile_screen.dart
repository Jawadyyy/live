import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:live/components/appbar.dart';
import 'package:live/components/primary_button.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  DateTime? _dob;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.userData['username'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData['phone_number'] ?? '',
    );
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    _dob =
        widget.userData['dob'] != null
            ? DateTime.tryParse(widget.userData['dob'])
            : null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dob) {
      setState(() => _dob = picked);
    }
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      int? calculatedAge = _dob != null ? _calculateAge(_dob!) : null;

      await _supabase
          .from('users')
          .update({
            'username': _usernameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'bio': _bioController.text.trim(),
            'dob': _dob != null ? _dob!.toIso8601String() : null,
            'age': calculatedAge,
          })
          .eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String label,
    String? value,
    TextEditingController? controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool isEditable = true,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    isEditable
                        ? TextFormField(
                            controller: controller,
                            maxLines: 1,
                            keyboardType: keyboardType,
                            validator: validator,
                            decoration: InputDecoration(
                              hintText: 'Enter $label',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          )
                        : Text(
                            value ?? label,
                            style: TextStyle(
                              fontSize: 16,
                              color: value != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Edit Profile'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header card with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 64, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      "Update your profile",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              _buildProfileTile(
                icon: Icons.person,
                label: "Username",
                controller: _usernameController,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? "Username required" : null,
              ),

              _buildProfileTile(
                icon: Icons.phone,
                label: "Phone Number",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),

              _buildProfileTile(
                icon: Icons.info,
                label: "Bio",
                controller: _bioController,
                maxLines: 3,
              ),

              _buildProfileTile(
                icon: Icons.calendar_today,
                label: "Date of Birth",
                value:
                    _dob != null
                        ? DateFormat.yMMMd().format(_dob!)
                        : "Select Date of Birth",
                isEditable: false,
                onTap: _pickDate,
                trailing: const Icon(Icons.edit_calendar),
              ),

              SizedBox(height: 40),

              MainButton(
                text: _isSaving ? "Saving..." : "Save Changes",
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveProfile,
                buttonColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
