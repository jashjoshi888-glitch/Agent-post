import 'package:flutter/material.dart';

/// The standard text input used in every form: label on top, friendly
/// validation messages underneath. Wraps Flutter's TextFormField so all
/// forms look identical.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.required = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final bool required;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLines: maxLines,
          autofocus: autofocus,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
