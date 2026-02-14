import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/bookings/booking_status_badge.dart';
import '../../widgets/bookings/early_late_fee_dialog.dart';
import 'booking_form_screen.dart';

/// Booking Detail Screen - Phase 1.9.7
/// 
/// Displays comprehensive booking information:
/// - Room details and status
/// - Guest information
/// - Check-in/out dates and times
/// - Payment details (total, deposit, balance)
/// - Booking source and special requests
/// - Action buttons (edit, check-in, check-out, cancel)
/// 
/// Follows design plan mockup from docs/HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md
class BookingDetailScreen extends ConsumerWidget {
  final int bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bookingDetails),
        actions: bookingAsync.whenOrNull(
          data: (booking) {
            final isEditable = booking.status != BookingStatus.checkedOut &&
                booking.status != BookingStatus.cancelled &&
                booking.status != BookingStatus.noShow;
            if (!isEditable) return <Widget>[];
            return <Widget>[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BookingFormScreen(booking: booking),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(context, ref),
              ),
            ];
          },
        ),
      ),
      body: bookingAsync.when(
        data: (booking) => _buildContent(context, ref, booking),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('${context.l10n.error}: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.goBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Booking booking) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi');
    final dateTimeFormat = DateFormat('HH:mm dd/MM/yyyy', 'vi');
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: booking.currency == 'VND' ? 'đ' : booking.currency,
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          // Room and Status Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                Text(
                  booking.roomNumber ?? '${context.l10n.roomNumber} ${booking.room}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (booking.roomTypeName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    booking.roomTypeName!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: 12),
                BookingStatusChip(status: booking.status),
              ],
            ),
          ),

          // Guest Information
          _buildSection(
            context,
            title: '👤 ${context.l10n.guestInfo}',
            children: [
              _buildInfoRow(context.l10n.name, booking.guestName),
              if (booking.guestPhone.isNotEmpty)
                _buildInfoRow(context.l10n.phoneNumber, booking.guestPhone),
              _buildInfoRow(context.l10n.guestCount, '${booking.guestCount} ${context.l10n.people}'),
            ],
          ),

          // Dates and Times
          _buildSection(
            context,
            title: '📅 ${context.l10n.timeLabel}',
            children: [
              _buildInfoRow(
                context.l10n.expectedCheckin,
                '${dateFormat.format(booking.checkInDate)} ${DateFormat('HH:mm').format(booking.checkInDate)}',
              ),
              _buildInfoRow(
                context.l10n.expectedCheckout,
                '${dateFormat.format(booking.checkOutDate)} ${DateFormat('HH:mm').format(booking.checkOutDate)}',
              ),
              _buildInfoRow(
                context.l10n.numberOfNights,
                '${booking.checkOutDate.difference(booking.checkInDate).inDays} ${context.l10n.nights}',
              ),
              if (booking.actualCheckIn != null)
                _buildInfoRow(
                  context.l10n.actualCheckin,
                  dateTimeFormat.format(booking.actualCheckIn!),
                  highlight: true,
                ),
              if (booking.actualCheckOut != null)
                _buildInfoRow(
                  context.l10n.actualCheckout,
                  dateTimeFormat.format(booking.actualCheckOut!),
                  highlight: true,
                ),
            ],
          ),

          // Payment Information
          _buildSection(
            context,
            title: '💰 ${context.l10n.payment}',
            children: [
              _buildInfoRow(
                context.l10n.ratePerNight,
                currencyFormat.format(booking.nightlyRate),
              ),
              _buildInfoRow(
                context.l10n.totalAmount,
                currencyFormat.format(booking.totalAmount),
                bold: true,
              ),
              if (booking.depositAmount > 0) ...[
                _buildInfoRow(
                  context.l10n.depositPaid,
                  currencyFormat.format(booking.depositAmount),
                  valueColor: Colors.green,
                ),
              ],
              _buildInfoRow(
                context.l10n.paymentMethod,
                _getPaymentMethodLabel(context, booking.paymentMethod),
              ),
            ],
          ),

          // Early/Late Fees Section
          if (booking.earlyCheckInFee > 0 || booking.lateCheckOutFee > 0 ||
              booking.status == BookingStatus.checkedIn ||
              booking.status == BookingStatus.confirmed)
            _buildSection(
              context,
              title: '⏰ ${context.l10n.feesAndCharges}',
              children: [
                if (booking.earlyCheckInFee > 0) ...[
                  _buildInfoRow(
                    '${context.l10n.earlyCheckInFee} (${booking.earlyCheckInHours}h)',
                    currencyFormat.format(booking.earlyCheckInFee),
                    valueColor: const Color(0xFF4CAF50),
                  ),
                ],
                if (booking.lateCheckOutFee > 0) ...[
                  _buildInfoRow(
                    '${context.l10n.lateCheckOutFee} (${booking.lateCheckOutHours}h)',
                    currencyFormat.format(booking.lateCheckOutFee),
                    valueColor: const Color(0xFFFF9800),
                  ),
                ],
                if (booking.totalFees > 0) ...[
                  const Divider(),
                  _buildInfoRow(
                    context.l10n.balanceDue,
                    currencyFormat.format(booking.calculatedBalanceDue),
                    bold: true,
                    valueColor: AppColors.warning,
                  ),
                ],
                // Fee action buttons
                if (booking.status == BookingStatus.checkedIn ||
                    booking.status == BookingStatus.confirmed) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (booking.status == BookingStatus.checkedIn ||
                          booking.status == BookingStatus.confirmed)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleRecordEarlyCheckIn(context, ref, booking),
                            icon: const Icon(Icons.login, size: 16),
                            label: Text(
                              context.l10n.earlyCheckIn,
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4CAF50),
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      if (booking.status == BookingStatus.checkedIn) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleRecordLateCheckOut(context, ref, booking),
                            icon: const Icon(Icons.logout, size: 16),
                            label: Text(
                              context.l10n.lateCheckOut,
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF9800),
                              side: const BorderSide(color: Color(0xFFFF9800)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),

          // Booking Source and Notes
          _buildSection(
            context,
            title: '📋 ${context.l10n.bookingInfo}',
            children: [
              _buildInfoRow(
                context.l10n.source,
                _getBookingSourceLabel(context, booking.source),
              ),
              if (booking.createdAt != null)
                _buildInfoRow(
                  context.l10n.bookingDate,
                  dateTimeFormat.format(booking.createdAt!),
                ),
              if (booking.specialRequests.isNotEmpty)
                _buildInfoRow(
                  context.l10n.specialRequests,
                  booking.specialRequests,
                ),
              if (booking.notes.isNotEmpty)
                _buildInfoRow(
                  context.l10n.internalNotes,
                  booking.notes,
                  valueColor: AppColors.textSecondary,
                ),
            ],
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(context, ref, booking),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool bold = false,
    bool highlight = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? (highlight ? AppColors.info : Colors.black87),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Booking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Check-in button - allows pending or confirmed status (via canCheckIn)
        if (booking.status.canCheckIn)
          ElevatedButton.icon(
            onPressed: () => _handleCheckIn(context, ref, booking),
            icon: const Icon(Icons.login),
            label: Text(context.l10n.checkIn),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.all(16),
            ),
          ),

        // Check-out button
        if (booking.status == BookingStatus.checkedIn) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _handleCheckOut(context, ref, booking),
            icon: const Icon(Icons.logout),
            label: Text(context.l10n.checkOut),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],

        // Cancel button
        if (booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.confirmed) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _handleCancel(context, ref, booking),
            icon: const Icon(Icons.cancel),
            label: Text(context.l10n.cancel),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],

        // Mark as no-show
        if (booking.status == BookingStatus.confirmed &&
            DateTime.now().isAfter(booking.checkInDate.add(const Duration(hours: 24)))) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _handleNoShow(context, ref, booking),
            icon: const Icon(Icons.person_off),
            label: Text(context.l10n.noShow),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  String _getBookingSourceLabel(BuildContext context, BookingSource source) {
    switch (source) {
      case BookingSource.walkIn:
        return 'Walk-in';
      case BookingSource.phone:
        return context.l10n.phoneNumber;
      case BookingSource.bookingCom:
        return 'Booking.com';
      case BookingSource.agoda:
        return 'Agoda';
      case BookingSource.airbnb:
        return 'Airbnb';
      case BookingSource.traveloka:
        return 'Traveloka';
      case BookingSource.otherOta:
        return 'OTA';
      case BookingSource.website:
        return 'Website';
      case BookingSource.other:
        return context.l10n.undefined;
    }
  }

  String _getPaymentMethodLabel(BuildContext context, PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return context.l10n.income;
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.otaCollect:
        return 'OTA';
      case PaymentMethod.other:
        return context.l10n.undefined;
    }
  }

  Future<void> _handleCheckIn(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${context.l10n.confirm} ${context.l10n.checkIn}'),
        content: Text('${context.l10n.confirm} ${context.l10n.checkIn} ${booking.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.checkIn),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).checkIn(bookingId);
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.checkIn} ${context.l10n.success}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.error}: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleCheckOut(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${context.l10n.confirm} ${context.l10n.checkOut}'),
        content: Text('${context.l10n.confirm} ${context.l10n.checkOut} ${booking.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.checkOut),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).checkOut(bookingId);
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.checkOut} ${context.l10n.success}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.error}: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.cancel),
        content: Text('${context.l10n.areYouSure} ${booking.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).cancelBooking(bookingId);
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.success)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.error}: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleNoShow(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.noShow),
        content: Text('${context.l10n.noShow} ${booking.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).markAsNoShow(bookingId);
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.success)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.error}: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.delete),
        content: Text('${context.l10n.areYouSure}\n\n${context.l10n.actionCannotBeUndone}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).deleteBooking(bookingId);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.success)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.error}: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleRecordEarlyCheckIn(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => EarlyLateFeeDialog(
        isEarlyCheckIn: true,
        nightlyRate: booking.nightlyRate,
        currentHours: booking.earlyCheckInHours,
        currentFee: booking.earlyCheckInFee,
      ),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).recordEarlyCheckIn(
              bookingId,
              hours: result['hours'] as double,
              fee: result['fee'] as int,
              notes: result['notes'] as String?,
              createFolioItem: result['create_folio_item'] as bool,
            );
        ref.invalidate(bookingByIdProvider(bookingId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.earlyCheckInRecorded)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.error}: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleRecordLateCheckOut(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => EarlyLateFeeDialog(
        isEarlyCheckIn: false,
        nightlyRate: booking.nightlyRate,
        currentHours: booking.lateCheckOutHours,
        currentFee: booking.lateCheckOutFee,
      ),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).recordLateCheckOut(
              bookingId,
              hours: result['hours'] as double,
              fee: result['fee'] as int,
              notes: result['notes'] as String?,
              createFolioItem: result['create_folio_item'] as bool,
            );
        ref.invalidate(bookingByIdProvider(bookingId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.lateCheckOutRecorded)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.error}: $e')),
          );
        }
      }
    }
  }
}
