import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../providers/finance_provider.dart';

/// Finance Form Screen for adding/editing income and expense entries
/// Phase 2.3 - Financial Management Frontend
class FinanceFormScreen extends ConsumerStatefulWidget {
  final EntryType entryType;
  final FinancialEntry? entry; // null for new, provided for edit

  const FinanceFormScreen({
    super.key,
    required this.entryType,
    this.entry,
  });

  @override
  ConsumerState<FinanceFormScreen> createState() => _FinanceFormScreenState();
}

class _FinanceFormScreenState extends ConsumerState<FinanceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _referenceController;
  late TextEditingController _notesController;

  // Form state
  int? _selectedCategoryId;
  DateTime _entryDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSubmitting = false;

  bool get isEdit => widget.entry != null;
  bool get isIncome => widget.entryType == EntryType.income;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _referenceController = TextEditingController();
    _notesController = TextEditingController();

    if (isEdit) {
      _initializeFromEntry(widget.entry!);
    }
  }

  void _initializeFromEntry(FinancialEntry entry) {
    _amountController.text = entry.amount.toStringAsFixed(0);
    _descriptionController.text = entry.description;
    _referenceController.text = entry.reference;
    _notesController.text = entry.notes;
    _selectedCategoryId = entry.category;
    _entryDate = entry.date;
    _paymentMethod = entry.paymentMethod;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categoriesAsync = isIncome
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? (isIncome ? '${l10n.edit} ${l10n.income}' : '${l10n.edit} ${l10n.expense}')
            : (isIncome ? '${l10n.add} ${l10n.income}' : '${l10n.add} ${l10n.expense}')),
        backgroundColor: isIncome ? AppColors.income : AppColors.expense,
        foregroundColor: Colors.white,
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildForm(context, categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              AppSpacing.gapVerticalMd,
              Text('${l10n.dataLoadError}: $error'),
              AppSpacing.gapVerticalMd,
              ElevatedButton(
                onPressed: () {
                  if (isIncome) {
                    ref.invalidate(incomeCategoriesProvider);
                  } else {
                    ref.invalidate(expenseCategoriesProvider);
                  }
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<FinancialCategory> categories) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: AppSpacing.paddingAll,
        children: [
          // Amount field (prominent)
          _buildAmountField(),
          AppSpacing.gapVerticalLg,

          // Category selection
          _buildCategorySelection(categories),
          AppSpacing.gapVerticalLg,

          // Description
          _buildDescriptionField(),
          AppSpacing.gapVerticalMd,

          // Date selection
          _buildDateField(),
          AppSpacing.gapVerticalMd,

          // Payment method
          _buildPaymentMethodSelection(),
          AppSpacing.gapVerticalMd,

          // Reference (optional)
          _buildReferenceField(),
          AppSpacing.gapVerticalMd,

          // Notes (optional)
          _buildNotesField(),
          AppSpacing.gapVerticalLg,

          // Submit button
          _buildSubmitButton(),
          AppSpacing.gapVerticalMd,
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    final l10n = context.l10n;
    return Container(
      padding: AppSpacing.paddingAll,
      decoration: BoxDecoration(
        color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalAmount,
            style: TextStyle(
              color: isIncome ? AppColors.income : AppColors.expense,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppSpacing.gapVerticalSm,
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsSeparatorInputFormatter(),
            ],
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              suffixText: 'VNĐ',
              suffixStyle: TextStyle(
                fontSize: 16,
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.errorTryAgain;
              }
              final amount = _parseAmount(value);
              if (amount <= 0) {
                return l10n.errorOccurred;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection(List<FinancialCategory> categories) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.financialCategories,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        AppSpacing.gapVerticalSm,
        if (categories.isEmpty)
          Container(
            padding: AppSpacing.paddingAll,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                l10n.noData,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: categories.map((category) {
              final isSelected = _selectedCategoryId == category.id;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.iconData,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    AppSpacing.gapHorizontalXs,
                    Text(category.name),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryId = selected ? category.id : null;
                  });
                },
                selectedColor: isIncome ? AppColors.income : AppColors.expense,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
        if (_selectedCategoryId == null && categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.enterOrSelectCategory,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    final l10n = context.l10n;
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: l10n.descriptionOptional,
        hintText: l10n.descriptionOptional,
        prefixIcon: const Icon(Icons.description),
      ),
      maxLength: 200,
    );
  }

  Widget _buildDateField() {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: Text(l10n.selectDate),
      subtitle: Text(
        DateFormat('dd/MM/yyyy HH:mm').format(_entryDate),
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _selectDate,
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_entryDate),
      );

      if (time != null && mounted) {
        setState(() {
          _entryDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Widget _buildPaymentMethodSelection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paymentMethod,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        AppSpacing.gapVerticalSm,
        Wrap(
          spacing: AppSpacing.sm,
          children: PaymentMethod.values.map((method) {
            final isSelected = _paymentMethod == method;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    method.icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  AppSpacing.gapHorizontalXs,
                  Text(method.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _paymentMethod = method);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReferenceField() {
    final l10n = context.l10n;
    return TextFormField(
      controller: _referenceController,
      decoration: InputDecoration(
        labelText: l10n.info,
        hintText: l10n.info,
        prefixIcon: const Icon(Icons.tag),
      ),
    );
  }

  Widget _buildNotesField() {
    final l10n = context.l10n;
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: l10n.internalNotes,
        hintText: l10n.internalNotes,
        prefixIcon: const Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton() {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isIncome ? AppColors.income : AppColors.expense,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(AppSpacing.md),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isEdit ? l10n.update : l10n.save,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  double _parseAmount(String value) {
    // Remove thousand separators and parse
    final cleanValue = value.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleanValue) ?? 0;
  }

  Future<void> _handleSubmit() async {
    final l10n = context.l10n;
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate category selection
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterOrSelectCategory),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = _parseAmount(_amountController.text);
      final description = _descriptionController.text.trim();

      final request = FinancialEntryRequest(
        category: _selectedCategoryId!,
        entryType: widget.entryType,
        amount: amount,
        date: _entryDate,
        description: description,
        paymentMethod: _paymentMethod,
        receiptNumber: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
      );

      final notifier = ref.read(financeNotifierProvider.notifier);

      if (isEdit) {
        await notifier.updateEntry(widget.entry!.id, request);
      } else {
        await notifier.createEntry(request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.success),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Input formatter that adds thousands separators
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove existing separators
    final cleanValue = newValue.text.replaceAll('.', '');

    // Parse to number
    final number = int.tryParse(cleanValue);
    if (number == null) {
      return oldValue;
    }

    // Format with thousand separators
    final formatter = NumberFormat('#,###', 'vi_VN');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
