import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../core/theme/app_colors.dart';

/// Booking Status Badge Widget - Displays booking status with color coding
///
/// Status colors:
/// - Pending: Orange (awaiting confirmation/payment)
/// - Confirmed: Blue (confirmed, not yet checked in)
/// - Checked In: Green (guest is staying)
/// - Checked Out: Grey (completed)
/// - Cancelled: Red (cancelled by guest/hotel)
/// - No Show: Dark red (guest didn't arrive)
class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool compact;

  const BookingStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(context, status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: compact ? 12 : 14, color: Colors.white),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              statusInfo.label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({String label, IconData icon, Color color}) _getStatusInfo(
    BuildContext context,
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.pending:
        return (
          label: context.l10n.statusPending,
          icon: Icons.schedule,
          color: AppColors.warning,
        );
      case BookingStatus.confirmed:
        return (
          label: context.l10n.statusConfirmed,
          icon: Icons.check_circle,
          color: AppColors.statusBlue,
        );
      case BookingStatus.checkedIn:
        return (
          label: context.l10n.statusCheckedIn,
          icon: Icons.hotel,
          color: AppColors.success,
        );
      case BookingStatus.checkedOut:
        return (
          label: context.l10n.statusCheckedOut,
          icon: Icons.done_all,
          color: AppColors.mutedAccent,
        );
      case BookingStatus.cancelled:
        return (
          label: context.l10n.statusCancelled,
          icon: Icons.cancel,
          color: AppColors.error,
        );
      case BookingStatus.noShow:
        return (
          label: context.l10n.statusNoShow,
          icon: Icons.person_off,
          color: AppColors.error,
        );
    }
  }
}

/// Booking Status Chip - Larger version for details screens
class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusInfo.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: 24, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            statusInfo.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  ({String label, IconData icon, Color color}) _getStatusInfo(
    BuildContext context,
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.pending:
        return (
          label: context.l10n.statusPending,
          icon: Icons.schedule,
          color: AppColors.warning,
        );
      case BookingStatus.confirmed:
        return (
          label: context.l10n.statusConfirmed,
          icon: Icons.check_circle,
          color: AppColors.statusBlue,
        );
      case BookingStatus.checkedIn:
        return (
          label: context.l10n.statusCheckedIn,
          icon: Icons.hotel,
          color: AppColors.success,
        );
      case BookingStatus.checkedOut:
        return (
          label: context.l10n.statusCheckedOut,
          icon: Icons.done_all,
          color: AppColors.mutedAccent,
        );
      case BookingStatus.cancelled:
        return (
          label: context.l10n.statusCancelled,
          icon: Icons.cancel,
          color: AppColors.error,
        );
      case BookingStatus.noShow:
        return (
          label: context.l10n.statusNoShow,
          icon: Icons.person_off,
          color: AppColors.error,
        );
    }
  }
}
