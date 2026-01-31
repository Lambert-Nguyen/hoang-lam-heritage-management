import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/finance.dart';
import '../../repositories/finance_repository.dart';

/// Dialog to record a deposit payment
class RecordDepositDialog extends StatefulWidget {
  final int bookingId;
  final double? suggestedAmount;
  final String? roomNumber;
  final String? guestName;

  const RecordDepositDialog({
    super.key,
    required this.bookingId,
    this.suggestedAmount,
    this.roomNumber,
    this.guestName,
  });

  @override
  State<RecordDepositDialog> createState() => _RecordDepositDialogState();
}

class _RecordDepositDialogState extends State<RecordDepositDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isLoading = false;
  String? _error;

  final FinanceRepository _repository = FinanceRepository();

  @override
  void initState() {
    super.initState();
    if (widget.suggestedAmount != null && widget.suggestedAmount! > 0) {
      _amountController.text = widget.suggestedAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      
      final request = DepositRecordRequest(
        booking: widget.bookingId,
        amount: amount,
        paymentMethod: _selectedMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final payment = await _repository.recordDeposit(request);

      if (mounted) {
        Navigator.of(context).pop(payment);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ghi nhận đặt cọc'),
          if (widget.roomNumber != null || widget.guestName != null)
            Text(
              [
                if (widget.roomNumber != null) 'Phòng ${widget.roomNumber}',
                if (widget.guestName != null) widget.guestName,
              ].join(' - '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Số tiền cọc',
                  prefixText: '₫ ',
                  border: const OutlineInputBorder(),
                  hintText: 'Nhập số tiền',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsSeparatorFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment method
              Text(
                'Phương thức thanh toán',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentMethod.values.take(6).map((method) {
                  final isSelected = _selectedMethod == method;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getMethodIcon(method),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(_getMethodName(method)),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMethod = method);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  border: OutlineInputBorder(),
                  hintText: 'Ghi chú thêm...',
                ),
                maxLines: 2,
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
        FilledButton(
          onPressed: _isLoading ? null : _submitDeposit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ghi nhận'),
        ),
      ],
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.momo:
        return Icons.phone_android;
      case PaymentMethod.vnpay:
        return Icons.qr_code;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.otaCollect:
        return Icons.business;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  String _getMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.card:
        return 'Thẻ';
      case PaymentMethod.otaCollect:
        return 'OTA';
      case PaymentMethod.other:
        return 'Khác';
    }
  }
}

/// Text input formatter to add thousand separators
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) {
      return oldValue;
    }

    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Show the record deposit dialog
Future<Payment?> showRecordDepositDialog(
  BuildContext context, {
  required int bookingId,
  double? suggestedAmount,
  String? roomNumber,
  String? guestName,
}) async {
  return showDialog<Payment>(
    context: context,
    builder: (context) => RecordDepositDialog(
      bookingId: bookingId,
      suggestedAmount: suggestedAmount,
      roomNumber: roomNumber,
      guestName: guestName,
    ),
  );
}
