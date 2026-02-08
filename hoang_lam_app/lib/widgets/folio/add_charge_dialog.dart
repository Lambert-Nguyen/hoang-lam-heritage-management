import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/finance.dart';
import '../../providers/providers.dart';

/// Dialog to add a new charge to a booking folio
class AddChargeDialog extends ConsumerStatefulWidget {
  final int bookingId;
  final VoidCallback? onChargeAdded;

  const AddChargeDialog({
    required this.bookingId,
    this.onChargeAdded,
    super.key,
  });

  @override
  ConsumerState<AddChargeDialog> createState() => _AddChargeDialogState();
}

class _AddChargeDialogState extends ConsumerState<AddChargeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();

  FolioItemType _selectedType = FolioItemType.service;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text) ?? 1;
  double get _unitPrice =>
      double.tryParse(_unitPriceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  double get _totalPrice => _quantity * _unitPrice;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm phí'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              const Text(
                'Loại phí',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTypeSelector(),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả *',
                  hintText: 'Nhập mô tả chi phí',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Quantity and unit price row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final qty = int.tryParse(value ?? '');
                        if (qty == null || qty < 1) {
                          return 'Số lượng >= 1';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Unit price
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _unitPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá *',
                        border: OutlineInputBorder(),
                        suffixText: '₫',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final price = double.tryParse(
                          value?.replaceAll(RegExp(r'[^\d]'), '') ?? '',
                        );
                        if (price == null || price <= 0) {
                          return 'Đơn giá > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Total display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      currencyFormat.format(_totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitCharge,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Thêm phí'),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    // Common types to display
    final commonTypes = [
      FolioItemType.service,
      FolioItemType.food,
      FolioItemType.laundry,
      FolioItemType.minibar,
      FolioItemType.extraBed,
      FolioItemType.earlyCheckin,
      FolioItemType.lateCheckout,
      FolioItemType.damage,
      FolioItemType.other,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: commonTypes.map((type) {
        final isSelected = _selectedType == type;
        return ChoiceChip(
          avatar: Icon(
            type.icon,
            size: 16,
            color: isSelected ? Colors.white : type.color,
          ),
          label: Text(type.displayName),
          selected: isSelected,
          selectedColor: type.color,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontSize: 12,
          ),
          onSelected: (_) {
            setState(() {
              _selectedType = type;
              // Auto-fill description based on type
              if (_descriptionController.text.isEmpty) {
                _descriptionController.text = type.displayName;
              }
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitCharge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = FolioItemCreateRequest(
        booking: widget.bookingId,
        itemType: _selectedType,
        description: _descriptionController.text.trim(),
        quantity: _quantity,
        unitPrice: _unitPrice,
        date: _selectedDate,
      );

      final success = await ref
          .read(folioNotifierProvider.notifier)
          .addCharge(request);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          widget.onChargeAdded?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm phí thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể thêm phí'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
