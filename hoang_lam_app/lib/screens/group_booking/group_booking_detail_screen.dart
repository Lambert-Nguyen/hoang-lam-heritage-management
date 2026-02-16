import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/group_booking.dart';
import '../../providers/group_booking_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen for displaying group booking details
class GroupBookingDetailScreen extends ConsumerStatefulWidget {
  final int bookingId;
  const GroupBookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<GroupBookingDetailScreen> createState() => _GroupBookingDetailScreenState();
}

class _GroupBookingDetailScreenState extends ConsumerState<GroupBookingDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookingAsync = ref.watch(groupBookingByIdProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupBookingDetails),
        actions: [
          bookingAsync.whenOrNull(
            data: (booking) => PopupMenuButton<String>(
              onSelected: (v) => _handleMenuAction(v, booking),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit), title: Text(l10n.edit), contentPadding: EdgeInsets.zero)),
                if (booking.status == GroupBookingStatus.tentative)
                  PopupMenuItem(value: 'confirm', child: ListTile(leading: const Icon(Icons.check_circle, color: AppColors.success), title: Text(l10n.confirm), contentPadding: EdgeInsets.zero)),
                if (booking.status == GroupBookingStatus.confirmed)
                  PopupMenuItem(value: 'check_in', child: ListTile(leading: const Icon(Icons.login, color: AppColors.statusBlue), title: Text(l10n.checkIn), contentPadding: EdgeInsets.zero)),
                if (booking.status == GroupBookingStatus.checkedIn)
                  PopupMenuItem(value: 'check_out', child: ListTile(leading: const Icon(Icons.logout, color: AppColors.statusPurple), title: Text(l10n.checkOut), contentPadding: EdgeInsets.zero)),
                if (booking.status == GroupBookingStatus.tentative || booking.status == GroupBookingStatus.confirmed)
                  PopupMenuItem(value: 'cancel', child: ListTile(leading: const Icon(Icons.cancel, color: AppColors.error), title: Text(l10n.cancel), contentPadding: EdgeInsets.zero)),
              ],
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: bookingAsync.when(
        data: (booking) => _buildContent(booking),
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: '${l10n.error}: $e', onRetry: () => ref.invalidate(groupBookingByIdProvider(widget.bookingId))),
      ),
      bottomNavigationBar: bookingAsync.whenOrNull(data: (booking) => _buildBottomBar(booking)),
    );
  }

  Widget _buildContent(GroupBooking booking) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: AppSpacing.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(color: booking.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(booking.status.icon, size: 18, color: booking.status.color),
              const SizedBox(width: 4),
              Text(booking.status.localizedName(context.l10n), style: TextStyle(color: booking.status.color, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(booking.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: l10n.contactLabel,
            icon: Icons.person,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(label: l10n.contactPerson, value: booking.contactName),
              if (booking.contactPhone.isNotEmpty) _InfoRow(label: l10n.phoneLabel, value: booking.contactPhone),
              if (booking.contactEmail.isNotEmpty) _InfoRow(label: 'Email', value: booking.contactEmail),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: l10n.bookingDetails,
            icon: Icons.hotel,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(label: l10n.checkInDate, value: _formatDate(booking.checkInDate)),
              _InfoRow(label: l10n.checkOutDate, value: _formatDate(booking.checkOutDate)),
              _InfoRow(label: l10n.roomCountLabel, value: '${booking.roomCount} ${l10n.roomsSuffix}'),
              _InfoRow(label: l10n.guestCountLabel, value: '${booking.guestCount} ${l10n.guestsSuffix}'),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: l10n.paymentLabel,
            icon: Icons.payment,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(label: l10n.totalAmount, value: '${_formatCurrency(booking.totalAmount)}₫', valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
              _InfoRow(label: l10n.depositLabel, value: '${_formatCurrency(booking.depositAmount)}₫'),
              if (booking.discountPercent > 0) _InfoRow(label: l10n.discountLabel, value: '${booking.discountPercent}%'),
              _InfoRow(label: l10n.paidStatus, value: booking.depositPaid ? l10n.yesLabel : l10n.notYetLabel, valueStyle: TextStyle(color: booking.depositPaid ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (booking.roomNumbers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.assignedRooms,
              icon: Icons.meeting_room,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: booking.roomNumbers.map((r) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                  child: Text('${l10n.roomLabel} $r', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ),
          ],
          if (booking.specialRequests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(title: l10n.specialRequests, icon: Icons.star, child: Text(booking.specialRequests)),
          ],
          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(title: l10n.notesLabel, icon: Icons.note, child: Text(booking.notes)),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildBottomBar(GroupBooking booking) {
    if (booking.status == GroupBookingStatus.checkedOut || booking.status == GroupBookingStatus.cancelled) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: AppSpacing.paddingAll,
        child: Row(
          children: [
            if (booking.status == GroupBookingStatus.tentative) ...[
              Expanded(child: AppButton(label: l10n.cancel, onPressed: _isLoading ? null : () => _cancelBooking(booking), isOutlined: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppButton(label: l10n.confirm, onPressed: _isLoading ? null : () => _confirmBooking(booking), icon: Icons.check_circle, isLoading: _isLoading)),
            ] else if (booking.status == GroupBookingStatus.confirmed) ...[
              Expanded(child: AppButton(label: l10n.assignRoomsLabel, onPressed: _isLoading ? null : () => _showRoomAssignmentDialog(booking), isOutlined: true, icon: Icons.meeting_room)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppButton(label: 'Check-in', onPressed: _isLoading ? null : () => _checkIn(booking), icon: Icons.login, isLoading: _isLoading)),
            ] else if (booking.status == GroupBookingStatus.checkedIn) ...[
              Expanded(child: AppButton(label: 'Check-out', onPressed: _isLoading ? null : () => _checkOut(booking), icon: Icons.logout, isLoading: _isLoading)),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, GroupBooking booking) {
    switch (action) {
      case 'edit': context.push('/group-bookings/${booking.id}/edit');
      case 'confirm': _confirmBooking(booking);
      case 'check_in': _checkIn(booking);
      case 'check_out': _checkOut(booking);
      case 'cancel': _cancelBooking(booking);
    }
  }

  Future<void> _confirmBooking(GroupBooking booking) async {
    final confirmed = await _showConfirmDialog(context.l10n.confirm, context.l10n.confirmGroupBooking);
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupBookingNotifierProvider.notifier).confirmBooking(booking.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.confirmedMsg)));
        ref.invalidate(groupBookingByIdProvider(widget.bookingId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIn(GroupBooking booking) async {
    if (booking.roomNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.assignRoomsFirstMsg), backgroundColor: AppColors.warning));
      return;
    }
    final confirmed = await _showConfirmDialog('Check-in', '${context.l10n.confirmGroupCheckIn} ${booking.name}?');
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupBookingNotifierProvider.notifier).checkInBooking(booking.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.checkedInMsg)));
        ref.invalidate(groupBookingByIdProvider(widget.bookingId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkOut(GroupBooking booking) async {
    final confirmed = await _showConfirmDialog('Check-out', '${context.l10n.confirmGroupCheckOut} ${booking.name}?');
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupBookingNotifierProvider.notifier).checkOutBooking(booking.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.checkedOutMsg)));
        ref.invalidate(groupBookingByIdProvider(widget.bookingId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(GroupBooking booking) async {
    final reason = await _showInputDialog(context.l10n.cancelReason, context.l10n.enterCancelReason);
    if (reason == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupBookingNotifierProvider.notifier).cancelBooking(booking.id, reason: reason);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.cancelledStatus)));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRoomAssignmentDialog(GroupBooking booking) async {
    final controller = TextEditingController(text: booking.rooms.join(', '));
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.assignRoomsLabel),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${context.l10n.roomsNeeded}: ${booking.roomCount}'),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: controller, decoration: InputDecoration(labelText: context.l10n.roomIdListLabel, hintText: context.l10n.roomIdListHint)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(context.l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    final roomIds = result.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
    if (roomIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.invalidRoomList), backgroundColor: AppColors.warning));
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(groupBookingNotifierProvider.notifier).assignRooms(booking.id, roomIds);
      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.roomsAssignedSuccess)));
        ref.invalidate(groupBookingByIdProvider(widget.bookingId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.confirm)),
      ],
    ));
  }

  Future<String?> _showInputDialog(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: Text(context.l10n.confirm)),
      ],
    )).then((result) {
      controller.dispose();
      return result;
    });
  }

  String _formatDate(String d) {
    try { final date = DateTime.parse(d); return '${date.day}/${date.month}/${date.year}'; } catch (_) { return d; }
  }

  String _formatCurrency(double amount) => amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 18, color: AppColors.textSecondary), const SizedBox(width: AppSpacing.sm), Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))]),
          const SizedBox(height: AppSpacing.sm),
          child,
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final TextStyle? valueStyle;
  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: valueStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
