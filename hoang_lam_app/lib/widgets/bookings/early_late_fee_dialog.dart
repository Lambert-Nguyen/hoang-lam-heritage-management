import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

/// Dialog for recording early check-in or late check-out fees.
///
/// Returns a map with keys: 'hours', 'fee', 'notes', 'create_folio_item'
/// or null if cancelled.
class EarlyLateFeeDialog extends StatefulWidget {
  /// Whether this is for early check-in (true) or late check-out (false)
  final bool isEarlyCheckIn;

  /// Current nightly rate for reference
  final int nightlyRate;

  /// Currently recorded hours (for editing)
  final double currentHours;

  /// Currently recorded fee (for editing)
  final int currentFee;

  const EarlyLateFeeDialog({
    super.key,
    required this.isEarlyCheckIn,
    required this.nightlyRate,
    this.currentHours = 0,
    this.currentFee = 0,
  });

  @override
  State<EarlyLateFeeDialog> createState() => _EarlyLateFeeDialogState();
}

class _EarlyLateFeeDialogState extends State<EarlyLateFeeDialog> {
  late TextEditingController _hoursController;
  late TextEditingController _feeController;
  late TextEditingController _notesController;
  bool _createFolioItem = true;

  final _formKey = GlobalKey<FormState>();
  final _currencyFormat = NumberFormat('#,##0', 'vi');

  // Preset hour options
  static const _presetHours = [1.0, 2.0, 3.0, 4.0, 6.0];

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(
      text: widget.currentHours > 0 ? widget.currentHours.toString() : '',
    );
    _feeController = TextEditingController(
      text: widget.currentFee > 0 ? widget.currentFee.toString() : '',
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _feeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectPresetHours(double hours) {
    setState(() {
      _hoursController.text = hours.toString();
      // Auto-calculate fee as a percentage of nightly rate
      _autoCalculateFee(hours);
    });
  }

  void _autoCalculateFee(double hours) {
    // Fee calculation: proportional to nightly rate
    // Standard check-in: 14:00, check-out: 12:00
    // Early check-in: fee per hour based on nightly rate / 24
    // Late check-out: same logic
    if (widget.nightlyRate > 0) {
      final hourlyRate = widget.nightlyRate / 24;
      final calculatedFee = (hourlyRate * hours).round();
      // Round to nearest 10000 VND
      final roundedFee = ((calculatedFee + 5000) ~/ 10000) * 10000;
      _feeController.text = roundedFee.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.isEarlyCheckIn
        ? l10n.earlyCheckIn
        : l10n.lateCheckOut;
    final icon = widget.isEarlyCheckIn ? Icons.login : Icons.logout;
    final color = widget.isEarlyCheckIn
        ? AppColors.success
        : AppColors.warning;

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.ratePerNight}: ${_currencyFormat.format(widget.nightlyRate)}đ',
                        style: TextStyle(fontSize: 13, color: color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preset hours
              Text(
                l10n.quickSelect,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedAccent,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetHours.map((h) {
                  final isSelected =
                      _hoursController.text == h.toString();
                  return ChoiceChip(
                    label: Text('${h.toStringAsFixed(h == h.roundToDouble() ? 0 : 1)}h'),
                    selected: isSelected,
                    selectedColor: color.withValues(alpha: 0.2),
                    onSelected: (_) => _selectPresetHours(h),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Hours input
              TextFormField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.numberOfHours,
                  hintText: '1.0 - 24.0',
                  suffixText: l10n.hours,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours <= 0) {
                    return l10n.invalidValue;
                  }
                  if (hours > 24) {
                    return l10n.maxHours24;
                  }
                  return null;
                },
                onChanged: (value) {
                  final hours = double.tryParse(value);
                  if (hours != null && hours > 0) {
                    _autoCalculateFee(hours);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Fee input
              TextFormField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.feeAmount,
                  hintText: '100,000',
                  suffixText: 'đ',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  final fee = int.tryParse(value);
                  if (fee == null || fee < 0) {
                    return l10n.invalidValue;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  hintText: l10n.optionalNotes,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Create folio item toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.createFolioItem,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  l10n.trackInFinancials,
                  style: const TextStyle(fontSize: 12),
                ),
                value: _createFolioItem,
                onChanged: (value) {
                  setState(() => _createFolioItem = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check, size: 18),
          label: Text(l10n.save),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final hours = double.parse(_hoursController.text);
    final fee = int.parse(_feeController.text);

    Navigator.of(context).pop({
      'hours': hours,
      'fee': fee,
      'notes': _notesController.text,
      'create_folio_item': _createFolioItem,
    });
  }
}
