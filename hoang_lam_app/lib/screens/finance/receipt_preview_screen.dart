import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/finance/currency_selector.dart';

/// Screen to preview and download a receipt for a booking
class ReceiptPreviewScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
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
      final repository = ref.read(financeRepositoryProvider);
      final receipt = await repository.generateReceipt(
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

  String _buildReceiptText() {
    final receipt = _receipt!;
    final l10n = context.l10n;
    final buffer = StringBuffer();

    buffer.writeln(l10n.appName);
    buffer.writeln(l10n.finance);
    buffer.writeln('#${receipt.receiptNumber}');
    buffer.writeln('${l10n.selectDate}: ${_formatDate(receipt.receiptDate)}');
    buffer.writeln();
    buffer.writeln('--- ${l10n.guestInfo} ---');
    buffer.writeln('${l10n.guestName}: ${receipt.guestName}');
    if (receipt.guestPhone != null) {
      buffer.writeln('${l10n.guestPhone}: ${receipt.guestPhone}');
    }
    buffer.writeln('${l10n.room}: ${receipt.roomNumber}');
    buffer.writeln();
    buffer.writeln('--- ${l10n.bookingInfo} ---');
    buffer.writeln('${l10n.checkIn}: ${_formatDate(receipt.checkInDate)}');
    buffer.writeln('${l10n.checkOut}: ${_formatDate(receipt.checkOutDate)}');
    buffer.writeln('${l10n.nights}: ${receipt.numberOfNights}');
    buffer.writeln('${l10n.ratePerNight}: ${_formatAmount(receipt.nightlyRate)}');
    buffer.writeln();
    buffer.writeln('--- ${l10n.expense} ---');
    buffer.writeln('${l10n.room}: ${_formatAmount(receipt.roomCharges)}');
    if (receipt.additionalCharges > 0) {
      buffer.writeln('${l10n.total}: ${_formatAmount(receipt.additionalCharges)}');
    }
    buffer.writeln('${l10n.totalAmount}: ${_formatAmount(receipt.totalAmount)}');
    buffer.writeln('${l10n.depositPaid}: ${_formatAmount(receipt.depositPaid)}');
    buffer.writeln('${l10n.balanceDue}: ${_formatAmount(receipt.balanceDue)}');

    return buffer.toString();
  }

  Future<void> _downloadReceipt() async {
    if (_receipt == null) return;

    try {
      final receiptText = _buildReceiptText();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/receipt_${_receipt!.receiptNumber}.txt');
      await file.writeAsString(receiptText);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.success}: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _shareReceipt() async {
    if (_receipt == null) return;

    try {
      final receiptText = _buildReceiptText();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/receipt_${_receipt!.receiptNumber}.txt');
      await file.writeAsString(receiptText);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: '${context.l10n.finance} #${_receipt!.receiptNumber}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.finance),
            if (widget.roomNumber != null)
              Text(
                '${l10n.room} ${widget.roomNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
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
              onPressed: _downloadReceipt,
              icon: const Icon(Icons.download),
              tooltip: l10n.save,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final l10n = context.l10n;
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
              l10n.dataLoadError,
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
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_receipt == null) {
      return Center(child: Text(l10n.noData));
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
                  onPressed: _shareReceipt,
                  icon: const Icon(Icons.share),
                  label: Text(l10n.save),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _downloadReceipt,
                  icon: const Icon(Icons.download),
                  label: Text(l10n.save),
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
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                  l10n.appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.finance,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '#${receipt.receiptNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${l10n.selectDate}: ${_formatDate(receipt.receiptDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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
                _buildInfoSection(theme, l10n.guestInfo, [
                  _buildInfoRow('${l10n.guestName}:', receipt.guestName),
                  if (receipt.guestPhone != null)
                    _buildInfoRow('${l10n.guestPhone}:', receipt.guestPhone!),
                  _buildInfoRow('${l10n.room}:', receipt.roomNumber),
                ]),
                const Divider(height: 24),
                _buildInfoSection(theme, l10n.bookingInfo, [
                  _buildInfoRow('${l10n.checkIn}:', _formatDate(receipt.checkInDate)),
                  _buildInfoRow('${l10n.checkOut}:', _formatDate(receipt.checkOutDate)),
                  _buildInfoRow('${l10n.nights}:', '${receipt.numberOfNights}'),
                  _buildInfoRow('${l10n.ratePerNight}:', _formatAmount(receipt.nightlyRate)),
                ]),
                const Divider(height: 24),
                _buildInfoSection(theme, l10n.expense, [
                  _buildInfoRow('${l10n.room}:', _formatAmount(receipt.roomCharges)),
                  if (receipt.additionalCharges > 0)
                    _buildInfoRow('${l10n.total}:', _formatAmount(receipt.additionalCharges)),
                  const Divider(height: 8),
                  _buildInfoRow('${l10n.totalAmount}:', _formatAmount(receipt.totalAmount), bold: true),
                  _buildInfoRow('${l10n.depositPaid}:', _formatAmount(receipt.depositPaid)),
                  _buildInfoRow(
                    '${l10n.balanceDue}:',
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
              l10n.success,
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
