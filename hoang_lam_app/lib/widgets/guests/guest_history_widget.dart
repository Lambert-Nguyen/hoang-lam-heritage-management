import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';

/// Widget to display guest booking history
class GuestHistoryWidget extends ConsumerWidget {
  final int guestId;
  final bool showHeader;

  const GuestHistoryWidget({
    super.key,
    required this.guestId,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(guestHistoryProvider(guestId));

    return historyAsync.when(
      data: (history) => _buildHistory(context, history),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildError(context, error.toString(), ref),
    );
  }

  Widget _buildHistory(BuildContext context, GuestHistoryResponse history) {
    if (history.bookings.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          _buildHeader(context, history),
          AppSpacing.gapVerticalMd,
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.bookings.length,
          separatorBuilder: (_, __) => AppSpacing.gapVerticalSm,
          itemBuilder: (context, index) {
            return _BookingHistoryCard(booking: history.bookings[index]);
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, GuestHistoryResponse history) {
    return Row(
      children: [
        const Icon(Icons.history, color: AppColors.textSecondary),
        AppSpacing.gapHorizontalSm,
        Text(
          context.l10n.bookingHistory,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${history.totalBookings} ${context.l10n.timesCount}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingAll,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(Icons.hotel_outlined, size: 48, color: AppColors.textHint),
          AppSpacing.gapVerticalSm,
          Text(
            context.l10n.noHistory,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, WidgetRef ref) {
    return Container(
      padding: AppSpacing.paddingAll,
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          AppSpacing.gapVerticalSm,
          Text(
            context.l10n.dataLoadError,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),
          AppSpacing.gapVerticalSm,
          TextButton.icon(
            onPressed: () => ref.invalidate(guestHistoryProvider(guestId)),
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}

/// Card displaying a single booking in history
class _BookingHistoryCard extends StatelessWidget {
  final GuestBookingSummary booking;

  const _BookingHistoryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final checkIn = dateFormat.format(booking.checkInDate);
    final checkOut = dateFormat.format(booking.checkOutDate);
    final nights = booking.checkOutDate.difference(booking.checkInDate).inDays;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.paddingCard,
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${context.l10n.room} ${booking.roomNumber}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppSpacing.gapHorizontalSm,
                if (booking.roomTypeName != null)
                  Text(
                    booking.roomTypeName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                _buildStatusBadge(context),
              ],
            ),
            AppSpacing.gapVerticalSm,
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.gapHorizontalXs,
                Text(
                  '$checkIn → $checkOut',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                AppSpacing.gapHorizontalSm,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$nights ${context.l10n.nights}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            Row(
              children: [
                Text(
                  _formatCurrency(booking.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (booking.isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.success,
                        ),
                        AppSpacing.gapHorizontalXs,
                        Text(
                          context.l10n.paid,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pending,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        AppSpacing.gapHorizontalXs,
                        Text(
                          context.l10n.unpaid,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final statusInfo = _getStatusInfo(context, booking.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        booking.statusDisplay ?? statusInfo.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: statusInfo.color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  ({Color color, String label}) _getStatusInfo(
    BuildContext context,
    String status,
  ) {
    switch (status) {
      case 'pending':
        return (color: AppColors.warning, label: context.l10n.statusPending);
      case 'confirmed':
        return (color: AppColors.info, label: context.l10n.statusConfirmed);
      case 'checked_in':
        return (color: AppColors.success, label: context.l10n.statusCheckedIn);
      case 'checked_out':
        return (
          color: AppColors.textSecondary,
          label: context.l10n.statusCheckedOut,
        );
      case 'cancelled':
        return (color: AppColors.error, label: context.l10n.statusCancelled);
      case 'no_show':
        return (color: AppColors.error, label: context.l10n.statusNoShow);
      default:
        return (color: AppColors.textSecondary, label: status);
    }
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }
}

/// Summary card showing total guest statistics
class GuestStatsSummary extends StatelessWidget {
  final int totalStays;
  final int totalBookings;
  final int totalSpent;
  final bool isVip;

  const GuestStatsSummary({
    super.key,
    required this.totalStays,
    required this.totalBookings,
    required this.totalSpent,
    required this.isVip,
  });

  /// Create from a Guest object
  factory GuestStatsSummary.fromGuest({Key? key, required Guest guest}) {
    return GuestStatsSummary(
      key: key,
      totalStays: guest.totalStays,
      totalBookings: guest.bookingCount,
      totalSpent: 0, // Will be loaded from history if needed
      isVip: guest.isVip,
    );
  }

  /// Convenience constructor that accepts a guest directly
  GuestStatsSummary.guest({super.key, required Guest guest})
    : totalStays = guest.totalStays,
      totalBookings = guest.bookingCount,
      totalSpent = 0,
      isVip = guest.isVip;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              context,
              icon: Icons.hotel_outlined,
              value: totalStays.toString(),
              label: context.l10n.staysLabel,
            ),
            _buildDivider(),
            _buildStat(
              context,
              icon: Icons.book_outlined,
              value: totalBookings.toString(),
              label: context.l10n.bookings,
            ),
            _buildDivider(),
            _buildStat(
              context,
              icon: Icons.payments_outlined,
              value: _formatCurrency(totalSpent),
              label: context.l10n.totalSpending,
            ),
            if (isVip) ...[
              _buildDivider(),
              _buildStat(
                context,
                icon: Icons.star,
                value: 'VIP',
                label: context.l10n.rankLabel,
                valueColor: AppColors.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: valueColor ?? AppColors.primary),
        AppSpacing.gapVerticalXs,
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: AppColors.divider);
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }
}
