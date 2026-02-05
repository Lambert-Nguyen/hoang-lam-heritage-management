import 'package:flutter/material.dart';

/// A styled dropdown widget for consistent form styling
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final String? hint;
  final String? label;
  final bool enabled;

  const AppDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.hint,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      isExpanded: true,
    );
  }
}
