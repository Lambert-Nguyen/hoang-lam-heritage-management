import 'package:flutter/material.dart';
import '../../models/finance.dart';
import '../../repositories/finance_repository.dart';
import '../../widgets/finance/currency_selector.dart';

/// Screen to preview and download a receipt for a booking
class ReceiptPreviewScreen extends StatefulWidget {
  final int bookingId;
  final String? guestName;
  final String? roomNumber;

  const ReceiptPreviewScreen({
    super.key,
    required this.bookingId,
    this.guestName,
    this.roomNumber,
  });

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  final FinanceRepository _repository = FinanceRepository();
  
  ReceiptData? _receipt;
  bool _isLoading = true;
  String? _error;
  String _selectedCurrency = 'VND';

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final receipt = await _repository.generateReceipt(
        widget.bookingId,
        currency: _selectedCurrency,
      );
      setState(() {
        _receipt = receipt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    // PDF download will be implemented when backend is deployed
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tính năng tải PDF đang phát triển')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hóa đơn'),
            if (widget.roomNumber != null)
              Text(
                'Phòng ${widget.roomNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
          ],
        ),
        actions: [
          CompactCurrencySelector(
            selectedCurrency: _selectedCurrency,
            onChanged: (currency) {
              setState(() {
                _selectedCurrency = currency;
              });
              _loadReceipt();
            },
          ),
          const SizedBox(width: 8),
          if (_receipt != null)
            IconButton(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.download),
              tooltip: 'Tải PDF',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải hóa đơn',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadReceipt,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_receipt == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReceiptPreview(theme),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng chia sẻ đang phát triển')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Chia sẻ'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.download),
                  label: const Text('Tải PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview(ThemeData theme) {
    final receipt = _receipt!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              children: [
                Text(
                  'HOÀNG LAM HERITAGE',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'HÓA ĐƠN',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Số: ${receipt.receiptNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Ngày: ${_formatDate(receipt.receiptDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Guest info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(theme, 'THÔNG TIN KHÁCH HÀNG', [
                  _buildInfoRow('Họ tên:', receipt.guestName),
                  if (receipt.guestPhone != null)
                    _buildInfoRow('Điện thoại:', receipt.guestPhone!),
                  _buildInfoRow('Phòng:', receipt.roomNumber),
                ]),
                const Divider(height: 24),
                _buildInfoSection(theme, 'THÔNG TIN LƯU TRÚ', [
                  _buildInfoRow('Nhận phòng:', _formatDate(receipt.checkInDate)),
                  _buildInfoRow('Trả phòng:', _formatDate(receipt.checkOutDate)),
                  _buildInfoRow('Số đêm:', '${receipt.numberOfNights} đêm'),
                  _buildInfoRow('Giá phòng/đêm:', _formatAmount(receipt.nightlyRate)),
                ]),
                const Divider(height: 24),
                _buildInfoSection(theme, 'CHI PHÍ', [
                  _buildInfoRow('Tiền phòng:', _formatAmount(receipt.roomCharges)),
                  if (receipt.additionalCharges > 0)
                    _buildInfoRow('Phụ thu:', _formatAmount(receipt.additionalCharges)),
                  const Divider(height: 8),
                  _buildInfoRow('Tổng cộng:', _formatAmount(receipt.totalAmount), bold: true),
                  _buildInfoRow('Đã thanh toán:', _formatAmount(receipt.depositPaid)),
                  _buildInfoRow(
                    'Còn lại:',
                    _formatAmount(receipt.balanceDue),
                    bold: true,
                    highlight: receipt.balanceDue > 0,
                  ),
                ]),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Text(
              'Cảm ơn quý khách đã sử dụng dịch vụ!',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false, bool highlight = false}) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.bold : null,
                color: highlight ? Colors.red : null,
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAmount(double amount) {
    final symbol = _selectedCurrency == 'VND' ? '₫' : _selectedCurrency;
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    )} $symbol';
  }
}
