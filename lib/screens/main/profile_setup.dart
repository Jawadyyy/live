import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/bottom_nav.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _dobController = TextEditingController();

  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  DateTime? _selectedDate;
  int _currentStep = 1;
  final int _totalSteps = 3;
  XFile? _profileImage;
  String? _calculatedAge;

  Future<void> _selectDate(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = themeProvider.getTheme(context);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              onSurface: theme.colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        // Calculate age automatically
        final age = (DateTime.now().difference(picked).inDays / 365).floor();
        _calculatedAge = '$age years';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile picture')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not found");

      // Prepare file
      final fileExtension = _profileImage!.path.split('.').last;
      final fileName = '${user.id}_profile.$fileExtension';
      final fileBytes = await _profileImage!.readAsBytes();

      // Upload or overwrite profile picture
      try {
        await Supabase.instance.client.storage
            .from('profile-pictures')
            .updateBinary(
              fileName,
              fileBytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } on StorageException catch (e) {
        if (e.statusCode == 404) {
          // First time upload
          await Supabase.instance.client.storage
              .from('profile-pictures')
              .uploadBinary(
                fileName,
                fileBytes,
                fileOptions: const FileOptions(upsert: true),
              );
        } else {
          rethrow;
        }
      }

      final imageUrl = Supabase.instance.client.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      // Update user profile data
      await Supabase.instance.client
          .from('users')
          .update({
            'username': _usernameController.text.trim(),
            'bio': _bioController.text.trim(),
            'dob': _dobController.text.trim(),
            'age': _calculatedAge?.replaceAll(' years', ''),
            'avatar_url': imageUrl,
            'is_profile_complete': true,
          })
          .eq('id', user.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomBottomNavBar()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildTextField(
          label: 'Username',
          hint: 'Enter your username',
          icon: Icons.person_outline,
          controller: _usernameController,
          validator:
              (value) => value!.isEmpty ? 'Please enter a username' : null,
        );
      case 2:
        return Column(
          children: [
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: _buildTextField(
                  label: 'Date of Birth',
                  hint: 'Select your date of birth',
                  icon: Icons.calendar_today_outlined,
                  controller: _dobController,
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Please select your date of birth'
                              : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_calculatedAge != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Text(
                      'Your age: $_calculatedAge',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case 3:
        return Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                backgroundImage:
                    _profileImage != null
                        ? FileImage(File(_profileImage!.path))
                        : null,
                child:
                    _profileImage == null
                        ? Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Upload Profile Picture',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField(
              label: 'Bio',
              hint: 'Tell us about yourself...',
              icon: Icons.edit,
              controller: _bioController,
              maxLines: 4,
              validator:
                  (value) => value!.isEmpty ? 'Please write a short bio' : null,
            ),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Let's get to know you better",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            StepProgressIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildStepContent(),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      if (_currentStep > 1)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: colorScheme.primary),
                            ),
                            child: Text(
                              "Back",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 1) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                  : Text(
                                    _currentStep < _totalSteps
                                        ? "Next"
                                        : "Complete Profile",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: colorScheme.onSurface.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }
}

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps * 2 - 1, (index) {
            final isCircle = index % 2 == 0;
            final stepIndex = (index ~/ 2) + 1;

            if (isCircle) {
              final isActive = stepIndex <= currentStep;
              return CircleAvatar(
                radius: 16,
                backgroundColor:
                    isActive ? colorScheme.primary : colorScheme.surfaceVariant,
                child: Text(
                  '$stepIndex',
                  style: TextStyle(
                    color:
                        isActive
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            } else {
              final isLineActive = stepIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  color:
                      isLineActive
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getStepTitle(currentStep),
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onBackground.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Basic Info';
      case 2:
        return 'Birth Date';
      case 3:
        return 'Profile Picture';
      default:
        return 'Step $step';
    }
  }
}
