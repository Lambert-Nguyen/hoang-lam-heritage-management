import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../../providers/booking_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/room_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/bookings/booking_status_badge.dart';
import '../../widgets/bookings/early_late_fee_dialog.dart';

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

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bookingDetails),
        actions: bookingAsync.whenOrNull(
          data: (booking) {
            final isEditable =
                booking.status != BookingStatus.checkedOut &&
                booking.status != BookingStatus.cancelled &&
                booking.status != BookingStatus.noShow;
            if (!isEditable) return <Widget>[];
            return <Widget>[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.push(AppRoutes.newBooking, extra: booking);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
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
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(getLocalizedErrorMessage(error, context.l10n)),
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

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bookingByIdProvider(bookingId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  booking.roomNumber ??
                      '${context.l10n.roomNumber} ${booking.room}',
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
            icon: Icons.person,
            title: context.l10n.guestInfo,
            children: [
              _buildInfoRow(context.l10n.name, booking.guestName),
              if (booking.guestPhone.isNotEmpty)
                _buildInfoRow(context.l10n.phoneNumber, booking.guestPhone),
              _buildInfoRow(
                context.l10n.guestCount,
                '${booking.guestCount} ${context.l10n.people}',
              ),
            ],
          ),

          // Dates and Times
          _buildSection(
            context,
            icon: Icons.schedule,
            title: context.l10n.timeLabel,
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
            icon: Icons.payments,
            title: context.l10n.payment,
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
                  valueColor: AppColors.success,
                ),
              ],
              _buildInfoRow(
                context.l10n.paymentMethod,
                _getPaymentMethodLabel(context, booking.paymentMethod),
              ),
            ],
          ),

          // Early/Late Fees Section
          if (booking.earlyCheckInFee > 0 ||
              booking.lateCheckOutFee > 0 ||
              booking.status == BookingStatus.checkedIn ||
              booking.status == BookingStatus.confirmed)
            _buildSection(
              context,
              icon: Icons.timer,
            title: context.l10n.feesAndCharges,
              children: [
                if (booking.earlyCheckInFee > 0) ...[
                  _buildInfoRow(
                    '${context.l10n.earlyCheckInFee} (${booking.earlyCheckInHours}h)',
                    currencyFormat.format(booking.earlyCheckInFee),
                    valueColor: AppColors.success,
                  ),
                ],
                if (booking.lateCheckOutFee > 0) ...[
                  _buildInfoRow(
                    '${context.l10n.lateCheckOutFee} (${booking.lateCheckOutHours}h)',
                    currencyFormat.format(booking.lateCheckOutFee),
                    valueColor: AppColors.warning,
                  ),
                ],
                if (booking.totalFees > 0) ...[
                  const Divider(),
                  _buildInfoRow(
                    context.l10n.balanceDue,
                    currencyFormat.format(booking.calculatedBalanceDue),
                    bold: true,
                    valueColor: booking.calculatedBalanceDue > 0
                        ? AppColors.error
                        : AppColors.success,
                  ),
                  if (booking.calculatedBalanceDue > 0 && !booking.isPaid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleMarkAsPaid(context, ref, booking),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(context.l10n.markAsPaid),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                          ),
                        ),
                      ),
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
                            onPressed: () => _handleRecordEarlyCheckIn(
                              context,
                              ref,
                              booking,
                            ),
                            icon: const Icon(Icons.login, size: 16),
                            label: Text(
                              context.l10n.earlyCheckIn,
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(color: AppColors.success),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      if (booking.status == BookingStatus.checkedIn) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleRecordLateCheckOut(
                              context,
                              ref,
                              booking,
                            ),
                            icon: const Icon(Icons.logout, size: 16),
                            label: Text(
                              context.l10n.lateCheckOut,
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: const BorderSide(color: AppColors.warning),
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

          // View Folio button (when checked in or checked out)
          if (booking.status == BookingStatus.checkedIn ||
              booking.status == BookingStatus.checkedOut)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('${AppRoutes.roomFolio}/${booking.id}');
                },
                icon: const Icon(Icons.receipt_long),
                label: Text(context.l10n.viewFolio),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

          // Booking Source and Notes
          _buildSection(
            context,
            icon: Icons.info_outline,
            title: context.l10n.bookingInfo,
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
    ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
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
            color: AppColors.mutedAccent.withValues(alpha: 0.1),
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
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
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
                color:
                    valueColor ?? (highlight ? AppColors.info : null),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) {
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
              backgroundColor: AppColors.success,
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

        // Swap room button
        if (booking.status == BookingStatus.checkedIn) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _handleSwapRoom(context, ref, booking),
            icon: const Icon(Icons.swap_horiz),
            label: Text(context.l10n.swapRoom),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],

        // Extend stay button
        if (booking.status == BookingStatus.checkedIn) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _handleExtendStay(context, ref, booking),
            icon: const Icon(Icons.date_range),
            label: Text(context.l10n.extendStay),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],

        // Split payment button
        if (booking.status == BookingStatus.checkedIn) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _handleSplitPayment(context, ref, booking),
            icon: const Icon(Icons.call_split),
            label: Text(context.l10n.splitPayment),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],

        // Partial refund button
        if (booking.status == BookingStatus.checkedIn ||
            booking.status == BookingStatus.checkedOut) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _handlePartialRefund(context, ref, booking),
            icon: const Icon(Icons.money_off),
            label: Text(context.l10n.partialRefund),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
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
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],

        // Mark as no-show
        if (booking.status == BookingStatus.confirmed &&
            DateTime.now().isAfter(
              booking.checkInDate.add(const Duration(hours: 24)),
            )) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _handleNoShow(context, ref, booking),
            icon: const Icon(Icons.person_off),
            label: Text(context.l10n.noShow),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  String _getBookingSourceLabel(BuildContext context, BookingSource source) {
    final l10n = context.l10n;
    switch (source) {
      case BookingSource.walkIn:
        return l10n.bookingSourceWalkIn;
      case BookingSource.phone:
        return l10n.bookingSourcePhone;
      case BookingSource.bookingCom:
        return l10n.bookingSourceBookingCom;
      case BookingSource.agoda:
        return l10n.bookingSourceAgoda;
      case BookingSource.airbnb:
        return l10n.bookingSourceAirbnb;
      case BookingSource.traveloka:
        return l10n.bookingSourceTraveloka;
      case BookingSource.otherOta:
        return l10n.bookingSourceOtherOta;
      case BookingSource.website:
        return l10n.bookingSourceWebsite;
      case BookingSource.other:
        return l10n.bookingSourceOther;
    }
  }

  String _getPaymentMethodLabel(BuildContext context, PaymentMethod method) {
    final l10n = context.l10n;
    switch (method) {
      case PaymentMethod.cash:
        return l10n.paymentMethodCash;
      case PaymentMethod.bankTransfer:
        return l10n.paymentMethodBankTransfer;
      case PaymentMethod.momo:
        return l10n.paymentMethodMomo;
      case PaymentMethod.vnpay:
        return l10n.paymentMethodVnpay;
      case PaymentMethod.card:
        return l10n.paymentMethodCard;
      case PaymentMethod.otaCollect:
        return l10n.paymentMethodOtaCollect;
      case PaymentMethod.other:
        return l10n.paymentMethodOther;
    }
  }

  Future<void> _handleCheckIn(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final roomNumber = booking.roomNumber ?? '${booking.room}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.confirmCheckInQuestion),
        content: Text(
          context.l10n.confirmCheckInMessage
              .replaceAll('{guestName}', booking.guestName)
              .replaceAll('{roomNumber}', roomNumber),
        ),
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
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(todayBookingsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.checkedInSuccess)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getLocalizedErrorMessage(e, context.l10n))));
        }
      }
    }
  }

  Future<void> _handleCheckOut(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final checkoutRoomNumber = booking.roomNumber ?? '${booking.room}';
    final now = DateTime.now();
    final isEarlyDeparture = now.isBefore(booking.checkOutDate);

    // Calculate night difference for early departure
    final scheduledNights =
        booking.checkOutDate.difference(booking.checkInDate).inDays;
    final actualNights =
        now.difference(booking.checkInDate).inDays.clamp(1, scheduledNights);

    Widget content;
    if (isEarlyDeparture) {
      final currencyFormat = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: booking.currency == 'VND' ? 'đ' : booking.currency,
        decimalDigits: 0,
      );
      final adjustedTotal = actualNights * booking.nightlyRate;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.confirmCheckOutMessage
                .replaceAll('{guestName}', booking.guestName)
                .replaceAll('{roomNumber}', checkoutRoomNumber),
          ),
          const SizedBox(height: 12),
          Text(
            '${context.l10n.earlyDeparture}:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 4),
          Text('${context.l10n.scheduledNights}: $scheduledNights'),
          Text('${context.l10n.actualNights}: $actualNights'),
          Text(
            '${context.l10n.adjustedTotal}: ${currencyFormat.format(adjustedTotal)}',
          ),
        ],
      );
    } else {
      content = Text(
        context.l10n.confirmCheckOutMessage
            .replaceAll('{guestName}', booking.guestName)
            .replaceAll('{roomNumber}', checkoutRoomNumber),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.confirmCheckOutQuestion),
        content: content,
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
        // Auto-set room to Cleaning after checkout
        if (booking.room > 0) {
          await ref
              .read(roomStateProvider.notifier)
              .updateRoomStatus(booking.room, RoomStatus.cleaning);
        }
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(todayBookingsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.checkoutSuccessViewReceipt),
              action: SnackBarAction(
                label: context.l10n.viewReceipt,
                onPressed: () {
                  context.push(
                    '${AppRoutes.receipt}/$bookingId',
                    extra: {
                      'guestName': booking.guestName,
                      'roomNumber': booking.roomNumber,
                    },
                  );
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getLocalizedErrorMessage(e, context.l10n))));
        }
      }
    }
  }

  Future<void> _handleSwapRoom(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    // Load available rooms
    final roomsAsync = await ref.read(allRoomsProvider.future);
    final availableRooms = roomsAsync
        .where((r) => r.status == RoomStatus.available)
        .toList();

    if (!context.mounted) return;

    if (availableRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noRoomsAvailable)),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        int? selectedRoomId;
        final reasonController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(context.l10n.swapRoom),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: context.l10n.selectRoom,
                    border: const OutlineInputBorder(),
                  ),
                  items: availableRooms
                      .map(
                        (r) => DropdownMenuItem<int>(
                          value: r.id,
                          child: Text(
                            '${r.number} - ${r.roomTypeName ?? ""}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedRoomId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: context.l10n.reason,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: selectedRoomId != null
                    ? () => Navigator.pop(ctx, {
                          'roomId': selectedRoomId,
                          'reason': reasonController.text,
                        })
                    : null,
                child: Text(context.l10n.confirm),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).swapRoom(
              booking.id,
              result['roomId'] as int,
              reason: result['reason'] as String?,
            );
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);
        ref.invalidate(dashboardSummaryProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.roomSwapped)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getLocalizedErrorMessage(e, context.l10n)),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleExtendStay(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final l10n = context.l10n;
    final currentCheckout = booking.checkOutDate;

    final newDate = await showDatePicker(
      context: context,
      initialDate: currentCheckout.add(const Duration(days: 1)),
      firstDate: currentCheckout.add(const Duration(days: 1)),
      lastDate: currentCheckout.add(const Duration(days: 365)),
      helpText: l10n.selectNewCheckoutDate,
    );

    if (newDate == null || !context.mounted) return;

    final additionalNights = newDate.difference(currentCheckout).inDays;
    final additionalCost = additionalNights * booking.nightlyRate;

    // Confirm with user
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.extendStay),
        content: Text(
          '${l10n.additionalNights}: $additionalNights\n'
          '${l10n.additionalCost}: ${currencyFormat.format(additionalCost)}\n\n'
          '${l10n.newCheckoutDate}: ${DateFormat("dd/MM/yyyy").format(newDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(bookingNotifierProvider.notifier)
          .extendStay(booking.id, newDate);
      ref.invalidate(bookingByIdProvider(bookingId));
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(todayBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.stayExtended)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getLocalizedErrorMessage(e, context.l10n)),
          ),
        );
      }
    }
  }

  Future<void> _handleCancel(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final cancelRoomNumber = booking.roomNumber ?? '${booking.room}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.confirmCancelQuestion),
        content: Text(
          context.l10n.confirmCancelMessage
              .replaceAll('{guestName}', booking.guestName)
              .replaceAll('{roomNumber}', cancelRoomNumber),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(bookingNotifierProvider.notifier)
            .cancelBooking(bookingId);
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(todayBookingsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getLocalizedErrorMessage(e, context.l10n))));
        }
      }
    }
  }

  Future<void> _handleNoShow(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final noShowRoomNumber = booking.roomNumber ?? '${booking.room}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.confirmNoShowQuestion),
        content: Text(
          context.l10n.confirmNoShowMessage
              .replaceAll('{guestName}', booking.guestName)
              .replaceAll('{roomNumber}', noShowRoomNumber),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(bookingNotifierProvider.notifier)
            .markAsNoShow(bookingId);
        ref.invalidate(bookingByIdProvider(bookingId));
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(todayBookingsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getLocalizedErrorMessage(e, context.l10n))));
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.delete),
        content: Text(
          '${context.l10n.areYouSure}\n\n${context.l10n.actionCannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(bookingNotifierProvider.notifier)
            .deleteBooking(bookingId);
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(todayBookingsProvider);
        ref.invalidate(roomsProvider);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getLocalizedErrorMessage(e, context.l10n))));
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
        await ref
            .read(bookingNotifierProvider.notifier)
            .recordEarlyCheckIn(
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getLocalizedErrorMessage(e, context.l10n))));
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
        await ref
            .read(bookingNotifierProvider.notifier)
            .recordLateCheckOut(
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getLocalizedErrorMessage(e, context.l10n))));
        }
      }
    }
  }

  Future<void> _handleSplitPayment(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final l10n = context.l10n;
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) => _SplitPaymentDialog(
        totalAmount: booking.totalAmount,
        l10n: l10n,
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        final notifier = ref.read(bookingNotifierProvider.notifier);
        final updated = await notifier.splitPayment(booking.id, result);
        if (updated != null && context.mounted) {
          ref.invalidate(bookingByIdProvider(booking.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.paymentSplitSuccess)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }

  Future<void> _handlePartialRefund(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final l10n = context.l10n;
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.partialRefund),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.totalAmount}: ${_formatCurrency(booking.totalAmount)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: l10n.refundAmount,
                  border: const OutlineInputBorder(),
                  suffixText: 'VND',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.pleaseEnterValue;
                  final amount = int.tryParse(v);
                  if (amount == null || amount <= 0) return l10n.pleaseEnterValue;
                  if (amount > booking.totalAmount) {
                    return l10n.refundExceedsTotal;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: l10n.reason,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.pleaseEnterValue : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final amount = int.parse(amountController.text);
        final notifier = ref.read(bookingNotifierProvider.notifier);
        final updated = await notifier.partialRefund(
          booking.id,
          amount: amount,
          reason: reasonController.text,
        );
        if (updated != null && context.mounted) {
          ref.invalidate(bookingByIdProvider(booking.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.refundProcessed)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
    amountController.dispose();
    reasonController.dispose();
  }

  Future<void> _handleMarkAsPaid(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.markAsPaid),
        content: Text(l10n.confirmAction),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final update = BookingUpdate.fromBooking(booking).copyWith(isPaid: true);
        await ref.read(bookingNotifierProvider.notifier).updateBooking(booking.id, update);
        ref.invalidate(bookingByIdProvider(booking.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.balanceSettled)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}đ';
  }
}

/// Dialog for splitting payment across multiple methods
class _SplitPaymentDialog extends StatefulWidget {
  final int totalAmount;
  final AppLocalizations l10n;

  const _SplitPaymentDialog({
    required this.totalAmount,
    required this.l10n,
  });

  @override
  State<_SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _PaymentSplit {
  PaymentMethod method;
  int amount;
  _PaymentSplit({required this.method, this.amount = 0});
}

class _SplitPaymentDialogState extends State<_SplitPaymentDialog> {
  final List<_PaymentSplit> _splits = [
    _PaymentSplit(method: PaymentMethod.cash),
    _PaymentSplit(method: PaymentMethod.bankTransfer),
  ];

  int get _totalSplit => _splits.fold(0, (sum, s) => sum + s.amount);
  int get _remaining => widget.totalAmount - _totalSplit;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.splitPayment),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.totalAmount}: ${_fmt(widget.totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(_splits.length, (i) => _buildSplitRow(i)),
            const SizedBox(height: 8),
            if (_splits.length < 4)
              TextButton.icon(
                onPressed: () => setState(() {
                  _splits.add(_PaymentSplit(method: PaymentMethod.momo));
                }),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addPaymentMethod),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.remaining,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  _fmt(_remaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _remaining == 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _remaining == 0
              ? () {
                  final result = _splits
                      .where((s) => s.amount > 0)
                      .map((s) => {
                            'method': s.method.name,
                            'amount': s.amount,
                          })
                      .toList();
                  Navigator.pop(context, result);
                }
              : null,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  Widget _buildSplitRow(int index) {
    final split = _splits[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<PaymentMethod>(
              value: split.method,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              items: PaymentMethod.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.displayName, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => split.method = v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: split.amount > 0 ? split.amount.toString() : '',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                setState(() {
                  split.amount = int.tryParse(v) ?? 0;
                });
              },
            ),
          ),
          if (_splits.length > 2)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: () => setState(() => _splits.removeAt(index)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
            ),
        ],
      ),
    );
  }

  String _fmt(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}đ';
  }
}
