import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Standard text input field
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helper;
  final String? error;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      autovalidateMode: autovalidateMode,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: error,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffix,
      ),
    );
  }
}

/// Phone number input with Vietnamese formatting
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? error;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const PhoneTextField({
    super.key,
    this.controller,
    this.label,
    this.error,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Số điện thoại',
      hint: '0901234567',
      error: error,
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone,
      maxLength: 11,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      onChanged: onChanged,
      validator: validator ?? _defaultPhoneValidator,
    );
  }

  String? _defaultPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    if (value.length < 10 || value.length > 11) {
      return 'Số điện thoại phải có 10-11 số';
    }
    if (!value.startsWith('0')) {
      return 'Số điện thoại phải bắt đầu bằng 0';
    }
    return null;
  }
}

/// Currency input with VND formatting
class CurrencyTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? error;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const CurrencyTextField({
    super.key,
    this.controller,
    this.label,
    this.error,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Số tiền',
      hint: '0',
      error: error,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.attach_money,
      suffix: const Padding(
        padding: EdgeInsets.only(right: AppSpacing.md),
        child: Text('₫', style: TextStyle(fontSize: 16)),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandsSeparatorInputFormatter(),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Input formatter for thousands separators
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(',', '');
    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    final formatted = _formatNumber(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

/// Dropdown select field
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final IconData? prefixIcon;

  const AppDropdown({
    super.key,
    this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
    );
  }
}

/// Date picker field
class DatePickerField extends StatelessWidget {
  final String? label;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onChanged;
  final String? hint;

  const DatePickerField({
    super.key,
    this.label,
    this.value,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value != null
        ? '${value!.day}/${value!.month}/${value!.year}'
        : '';

    return AppTextField(
      label: label,
      hint: hint ?? 'dd/mm/yyyy',
      controller: TextEditingController(text: displayValue),
      readOnly: true,
      prefixIcon: Icons.calendar_today,
      onTap: () => _showDatePicker(context),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      locale: const Locale('vi'),
    );
    if (picked != null && onChanged != null) {
      onChanged!(picked);
    }
  }
}
