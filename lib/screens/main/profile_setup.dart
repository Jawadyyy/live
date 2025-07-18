import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:live/auth/auth_service.dart';
import 'package:live/components/bottom_nav.dart';
import 'package:live/components/secondary_button.dart';
import 'package:live/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:live/components/primary_button.dart';
import 'package:live/components/text_field.dart';

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
    final isDark = theme.brightness == Brightness.dark;

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
            colorScheme:
                isDark
                    ? ColorScheme.dark(
                      primary: theme.colorScheme.primary,
                      onPrimary: theme.colorScheme.onPrimary,
                      surface: theme.colorScheme.surface,
                      onSurface: theme.colorScheme.onSurface,
                    )
                    : ColorScheme.light(
                      primary: theme.colorScheme.primary,
                      onPrimary: theme.colorScheme.onPrimary,
                      surface: theme.colorScheme.surface,
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
        return CustomTextField(
          controller: _usernameController,
          label: 'Username',
          hintText: 'Enter your username',
          prefixIcon: Icons.person_outline,
          validator:
              (value) => value!.isEmpty ? 'Please enter a username' : null,
        );
      case 2:
        return Column(
          children: [
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: _dobController,
                  label: 'Date of Birth',
                  hintText: 'Select your date of birth',
                  prefixIcon: Icons.calendar_today_outlined,
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
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
            Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child:
                        _profileImage != null
                            ? Image.file(
                              File(_profileImage!.path),
                              fit: BoxFit.cover,
                            )
                            : Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.3),
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                            ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            CustomTextField(
              controller: _bioController,
              label: 'Bio',
              hintText: 'Tell us about yourself...',
              prefixIcon: Icons.edit,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with step indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  Text(
                    "Complete Your Profile",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Step $_currentStep of $_totalSteps",
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StepProgressIndicator(
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                  ),
                  const SizedBox(height: 32),
                ],
              ),

              // Form content
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStepContent(),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        if (_currentStep > 1)
                          Expanded(
                            child: SecondButton(
                              text: "Back",
                              onPressed: _previousStep,
                              isFullWidth: true,
                              textColor: Colors.white,
                            ),
                          ),
                        if (_currentStep > 1) const SizedBox(width: 16),
                        Expanded(
                          child: MainButton(
                            text:
                                _currentStep < _totalSteps
                                    ? "Continue"
                                    : "Finish",
                            onPressed: _isLoading ? null : _nextStep,
                            isFullWidth: true,
                            isLoading: _isLoading,
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
      ),
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
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.surfaceVariant.withOpacity(0.3);

    return Column(
      children: [
        SizedBox(
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: currentStep / totalSteps,
              backgroundColor: inactiveColor,
              color: activeColor,
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isActive = stepNumber <= currentStep;

            return Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : inactiveColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: TextStyle(
                        color:
                            isActive
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepTitle(stepNumber),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color:
                        isActive
                            ? colorScheme.onBackground
                            : colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Username';
      case 2:
        return 'Birth Date';
      case 3:
        return 'Profile';
      default:
        return 'Step $step';
    }
  }
}
