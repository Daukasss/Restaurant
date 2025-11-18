import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool isPhoneNumber;
  final bool isMultiplePhones; // Added parameter for multiple phones
  final int?
      maxLength; // Added maxLength parameter for flexible character limit

  const CustomTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.initialValue,
    this.onChanged,
    this.enabled = true,
    this.isPhoneNumber = false,
    this.isMultiplePhones = false,
    this.maxLength, // Added maxLength parameter
  });

  @override
  Widget build(BuildContext context) {
    final effectiveKeyboardType = keyboardType ??
        (isPhoneNumber
            ? TextInputType.phone
            : (obscureText || isMultiplePhones)
                ? TextInputType.text
                : TextInputType.multiline);

    final effectiveTextInputAction = (isPhoneNumber || obscureText)
        ? TextInputAction.done
        : isMultiplePhones
            ? TextInputAction.newline
            : TextInputAction.newline;

    List<TextInputFormatter>? effectiveInputFormatters;

    if (isPhoneNumber && !isMultiplePhones) {
      // Phone number formatting with fixed 17 character limit
      effectiveInputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
        LengthLimitingTextInputFormatter(17),
        PhoneNumberFormatter(),
      ];
    } else if (maxLength != null) {
      // Custom maxLength limit
      effectiveInputFormatters = [
        LengthLimitingTextInputFormatter(maxLength),
      ];
    }
    // If both are null/false, no formatters applied = no limit

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: effectiveKeyboardType,
      textInputAction: effectiveTextInputAction,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      inputFormatters: effectiveInputFormatters,
      minLines: (!obscureText && !isPhoneNumber) || isMultiplePhones ? 1 : null,
      maxLines: (!obscureText && !isPhoneNumber) || isMultiplePhones ? null : 1,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // If user deletes everything — leave +7
    if (text.isEmpty || text == '+') {
      return const TextEditingValue(
        text: '+7 ',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    // Remove everything except digits
    String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // Always start with 7
    if (!digitsOnly.startsWith('7')) {
      digitsOnly = '7$digitsOnly';
    }

    // Limit length to 11 digits after +7
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    // Format: +7 777 777 77 77
    String formatted = '+7';
    if (digitsOnly.length > 1) {
      formatted += ' ${digitsOnly.substring(1, digitsOnly.length.clamp(1, 4))}';
    }
    if (digitsOnly.length > 4) {
      formatted += ' ${digitsOnly.substring(4, digitsOnly.length.clamp(4, 7))}';
    }
    if (digitsOnly.length > 7) {
      formatted += ' ${digitsOnly.substring(7, digitsOnly.length.clamp(7, 9))}';
    }
    if (digitsOnly.length > 9) {
      formatted += ' ${digitsOnly.substring(9)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
