import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:live/screens/auth/auth_ui.dart';

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
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAuthRadius),
          borderSide: BorderSide(color: c, width: w),
        );

    return IntlPhoneField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      cursorColor: AuthColors.accentLight,
      style: const TextStyle(color: AuthColors.text, fontSize: 15),
      dropdownTextStyle: const TextStyle(color: AuthColors.text, fontSize: 15),
      dropdownIcon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AuthColors.muted,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Phone number',
        hintStyle: const TextStyle(color: AuthColors.muted, fontSize: 15),
        filled: true,
        fillColor: AuthColors.field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: border(AuthColors.fieldBorder),
        focusedBorder: border(AuthColors.accent),
        errorBorder: border(AuthColors.pink),
        focusedErrorBorder: border(AuthColors.pink),
      ),
      initialCountryCode: 'PK',
      onChanged: (phone) {
        widget.onPhoneChanged(phone.completeNumber);
      },
      onCountryChanged: (country) {},
    );
  }
}
