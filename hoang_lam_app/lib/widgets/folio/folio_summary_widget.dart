import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
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
    final balanceColor = isSettled ? AppColors.success : AppColors.error;

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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                          const Icon(
                            Icons.meeting_room,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${context.l10n.room} ${summary.roomNumber}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
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
                    color: balanceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: balanceColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    isSettled ? context.l10n.paid : context.l10n.outstandingBalance,
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
              label: context.l10n.roomCharges,
              amount: summary.roomCharges,
              color: AppColors.info,
            ),

            const SizedBox(height: 8),

            _buildSummaryRow(
              icon: Icons.add_circle_outline,
              label: context.l10n.additionalCharges,
              amount: summary.additionalCharges,
              color: AppColors.warning,
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Total charges
            _buildSummaryRow(
              icon: Icons.receipt_long,
              label: context.l10n.totalCharges,
              amount: summary.totalCharges,
              color: AppColors.primary,
              isBold: true,
            ),

            const SizedBox(height: 8),

            // Payments
            _buildSummaryRow(
              icon: Icons.payment,
              label: context.l10n.paid,
              amount: summary.totalPayments,
              color: AppColors.success,
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
                    Text(
                      context.l10n.remainingBalance,
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
                  color: AppColors.statusAmberLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusAmberBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.statusAmberIcon,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${context.l10n.guestOwes} ${currencyFormat.format(summary.outstandingAmount)}',
                        style: TextStyle(
                          color: AppColors.statusAmberDark,
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
