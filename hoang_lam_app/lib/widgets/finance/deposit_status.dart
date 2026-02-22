import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../core/theme/app_colors.dart';

/// Widget to display deposit status for a booking
class DepositStatusIndicator extends StatelessWidget {
  final double requiredDeposit;
  final double paidDeposit;
  final bool showLabel;
  final VoidCallback? onTap;

  const DepositStatusIndicator({
    super.key,
    required this.requiredDeposit,
    required this.paidDeposit,
    this.showLabel = true,
    this.onTap,
  });

  double get progress =>
      requiredDeposit > 0
          ? (paidDeposit / requiredDeposit).clamp(0.0, 1.0)
          : 0.0;
  double get outstanding =>
      (requiredDeposit - paidDeposit).clamp(0.0, requiredDeposit);
  bool get isFullyPaid => paidDeposit >= requiredDeposit;

  Color _getStatusColor(ThemeData theme) {
    if (isFullyPaid) return AppColors.success;
    if (paidDeposit > 0) return AppColors.warning;
    return AppColors.error;
  }

  String _getStatusText(BuildContext context) {
    if (isFullyPaid) return context.l10n.depositPaid;
    if (paidDeposit > 0) return context.l10n.depositShort;
    return context.l10n.noDeposit;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(theme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isFullyPaid ? Icons.check_circle : Icons.warning,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                if (showLabel)
                  Text(
                    _getStatusText(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                const Spacer(),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: statusColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${context.l10n.depositPaidStatus}: ${_formatAmount(paidDeposit)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${context.l10n.requiredAmount}: ${_formatAmount(requiredDeposit)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount.toInt())}₫';
  }
}

/// Card displaying outstanding deposit info
class OutstandingDepositCard extends StatelessWidget {
  final OutstandingDeposit deposit;
  final VoidCallback? onRecordDeposit;
  final VoidCallback? onTap;

  const OutstandingDepositCard({
    super.key,
    required this.deposit,
    this.onRecordDeposit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      deposit.roomNumber,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deposit.guestName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(deposit.checkInDate)} - ${_formatDate(deposit.checkOutDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DepositStatusIndicator(
                requiredDeposit: deposit.requiredDeposit,
                paidDeposit: deposit.paidDeposit,
                showLabel: false,
              ),
              if (deposit.outstanding > 0 && onRecordDeposit != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${context.l10n.amountShort}: ${_formatAmount(deposit.outstanding)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: onRecordDeposit,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(context.l10n.recordDepositBtn),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount.toInt())}₫';
  }
}

/// List view for outstanding deposits
class OutstandingDepositsList extends StatelessWidget {
  final List<OutstandingDeposit> deposits;
  final Function(OutstandingDeposit)? onRecordDeposit;
  final Function(OutstandingDeposit)? onTap;
  final bool isLoading;
  final String? emptyMessage;

  const OutstandingDepositsList({
    super.key,
    required this.deposits,
    this.onRecordDeposit,
    this.onTap,
    this.isLoading = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? context.l10n.noPendingDeposits,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deposits.length,
      itemBuilder: (context, index) {
        final deposit = deposits[index];
        return OutstandingDepositCard(
          deposit: deposit,
          onRecordDeposit:
              onRecordDeposit != null ? () => onRecordDeposit!(deposit) : null,
          onTap: onTap != null ? () => onTap!(deposit) : null,
        );
      },
    );
  }
}
