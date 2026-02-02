import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/finance.dart';

/// Widget to display folio summary (totals, balance, guest info)
class FolioSummaryWidget extends StatelessWidget {
  final BookingFolioSummary summary;
  final NumberFormat currencyFormat;

  const FolioSummaryWidget({
    required this.summary,
    required this.currencyFormat,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isSettled = summary.isSettled;
    final balanceColor = isSettled ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guest info header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.guestName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Phòng ${summary.roomNumber}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Balance status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: balanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: balanceColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    isSettled ? 'Đã thanh toán' : 'Còn nợ',
                    style: TextStyle(
                      color: balanceColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Charges breakdown
            _buildSummaryRow(
              icon: Icons.hotel,
              label: 'Tiền phòng',
              amount: summary.roomCharges,
              color: Colors.blue,
            ),

            const SizedBox(height: 8),

            _buildSummaryRow(
              icon: Icons.add_circle_outline,
              label: 'Phí bổ sung',
              amount: summary.additionalCharges,
              color: Colors.orange,
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Total charges
            _buildSummaryRow(
              icon: Icons.receipt_long,
              label: 'Tổng chi phí',
              amount: summary.totalCharges,
              color: AppColors.primary,
              isBold: true,
            ),

            const SizedBox(height: 8),

            // Payments
            _buildSummaryRow(
              icon: Icons.payment,
              label: 'Đã thanh toán',
              amount: summary.totalPayments,
              color: Colors.green,
              prefix: '-',
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Balance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSettled ? Icons.check_circle : Icons.pending,
                      color: balanceColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Còn lại',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  currencyFormat.format(summary.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: balanceColor,
                  ),
                ),
              ],
            ),

            // Outstanding amount if applicable
            if (summary.outstandingAmount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Khách còn nợ ${currencyFormat.format(summary.outstandingAmount)}',
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    bool isBold = false,
    String? prefix,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '${prefix ?? ''}${currencyFormat.format(amount)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
