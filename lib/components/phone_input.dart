import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class PhoneForm extends StatefulWidget {
  final Function(String) onPhoneChanged;
  final String label;
  final String? hintText;
  final String? Function(String?)? validator;

  const PhoneForm({
    super.key,
    required this.onPhoneChanged,
    required this.label,
    this.hintText,
    this.validator,
  });

  @override
  _PhoneFormState createState() => _PhoneFormState();
}

class _PhoneFormState extends State<PhoneForm> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.colorScheme.onSurface.withOpacity(0.4);
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.1);

    return IntlPhoneField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(
            'assets/images/icons/phone.png',
            width: 24,
            height: 24,
            color: hintColor,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      initialCountryCode: 'US',
      onChanged: (phone) {
        widget.onPhoneChanged(phone.completeNumber);
      },
      onCountryChanged: (country) {
        // ignore: avoid_print
        print('Country changed to: ${country.name}');
      },
    );
  }
}
