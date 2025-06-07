import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class CustomPhoneInput extends StatelessWidget {
  final PhoneNumber initialValue;
  final TextEditingController controller;
  final ValueChanged<PhoneNumber> onInputChanged;
  final ValueChanged<bool> onInputValidated;
  final String? Function(String?)? validator;

  const CustomPhoneInput({
    super.key,
    required this.initialValue,
    required this.controller,
    required this.onInputChanged,
    required this.onInputValidated,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final hintColor = theme.colorScheme.onSurface.withOpacity(0.4);
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InternationalPhoneNumberInput(
            onInputChanged: onInputChanged,
            onInputValidated: onInputValidated,
            selectorConfig: const SelectorConfig(
              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
              showFlags: true,
              useEmoji: true,
              leadingPadding: 8,
            ),
            spaceBetweenSelectorAndTextField: 0,
            ignoreBlank: false,
            autoValidateMode: AutovalidateMode.disabled,
            selectorTextStyle: TextStyle(color: textColor),
            initialValue: initialValue,
            textFieldController: controller,
            formatInput: true,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputDecoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              isDense: true,
              border: InputBorder.none,
              hintText: 'Enter phone number',
              hintStyle: TextStyle(color: Colors.black, fontSize: 16),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
            ),
            textStyle: TextStyle(color: textColor, fontSize: 16),
            cursorColor: theme.primaryColor,
            searchBoxDecoration: InputDecoration(
              contentPadding: const EdgeInsets.all(16),
              labelText: 'Search country',
              labelStyle: TextStyle(color: textColor),
              prefixIcon: Icon(Icons.search, color: hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
