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
                  PopupMenuItem(value: 'confirm', child: ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: Text(l10n.confirm), contentPadding: EdgeInsets.zero)),
                if (booking.status == GroupBookingStatus.confirmed)
                  PopupMenuItem(value: 'check_in', child: ListTile(leading: const Icon(Icons.login, color: Colors.blue), title: Text(l10n.checkIn), contentPadding: EdgeInsets.zero)),
                if (booking.status == GroupBookingStatus.checkedIn)
                  PopupMenuItem(value: 'check_out', child: ListTile(leading: const Icon(Icons.logout, color: Colors.purple), title: Text(l10n.checkOut), contentPadding: EdgeInsets.zero)),
                if (booking.status == GroupBookingStatus.tentative || booking.status == GroupBookingStatus.confirmed)
                  PopupMenuItem(value: 'cancel', child: ListTile(leading: const Icon(Icons.cancel, color: Colors.red), title: Text(l10n.cancel), contentPadding: EdgeInsets.zero)),
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
              Text(booking.status.displayName, style: TextStyle(color: booking.status.color, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(booking.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Liên hệ',
            icon: Icons.person,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(label: 'Người liên hệ', value: booking.contactName),
              if (booking.contactPhone.isNotEmpty) _InfoRow(label: 'Điện thoại', value: booking.contactPhone),
              if (booking.contactEmail.isNotEmpty) _InfoRow(label: 'Email', value: booking.contactEmail),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Chi tiết đặt phòng',
            icon: Icons.hotel,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(label: 'Ngày nhận phòng', value: _formatDate(booking.checkInDate)),
              _InfoRow(label: 'Ngày trả phòng', value: _formatDate(booking.checkOutDate)),
              _InfoRow(label: 'Số phòng', value: '${booking.roomCount} phòng'),
              _InfoRow(label: 'Số khách', value: '${booking.guestCount} khách'),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Thanh toán',
            icon: Icons.payment,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(label: 'Tổng tiền', value: '${_formatCurrency(booking.totalAmount)}₫', valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
              _InfoRow(label: 'Đặt cọc', value: '${_formatCurrency(booking.depositAmount)}₫'),
              if (booking.discountPercent > 0) _InfoRow(label: 'Giảm giá', value: '${booking.discountPercent}%'),
              _InfoRow(label: 'Đã thanh toán', value: booking.depositPaid ? 'Có' : 'Chưa', valueStyle: TextStyle(color: booking.depositPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (booking.roomNumbers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Phòng đã phân',
              icon: Icons.meeting_room,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: booking.roomNumbers.map((r) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                  child: Text('Phòng $r', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ),
          ],
          if (booking.specialRequests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(title: 'Yêu cầu đặc biệt', icon: Icons.star, child: Text(booking.specialRequests)),
          ],
          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(title: 'Ghi chú', icon: Icons.note, child: Text(booking.notes)),
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
    return SafeArea(
      child: Padding(
        padding: AppSpacing.paddingAll,
        child: Row(
          children: [
            if (booking.status == GroupBookingStatus.tentative) ...[
              Expanded(child: AppButton(label: 'Hủy', onPressed: _isLoading ? null : () => _cancelBooking(booking), isOutlined: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppButton(label: 'Xác nhận', onPressed: _isLoading ? null : () => _confirmBooking(booking), icon: Icons.check_circle, isLoading: _isLoading)),
            ] else if (booking.status == GroupBookingStatus.confirmed) ...[
              Expanded(child: AppButton(label: 'Phân phòng', onPressed: _isLoading ? null : () => _showRoomAssignmentDialog(booking), isOutlined: true, icon: Icons.meeting_room)),
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
    final confirmed = await _showConfirmDialog('Xác nhận', 'Xác nhận đặt phòng đoàn?');
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupBookingNotifierProvider.notifier).confirmBooking(booking.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác nhận')));
        ref.invalidate(groupBookingByIdProvider(widget.bookingId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIn(GroupBooking booking) async {
    if (booking.roomNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng phân phòng trước'), backgroundColor: Colors.orange));
      return;
    }
    final confirmed = await _showConfirmDialog('Check-in', 'Xác nhận check-in cho đoàn ${booking.name}?');
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupBookingNotifierProvider.notifier).checkInBooking(booking.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã check-in')));
        ref.invalidate(groupBookingByIdProvider(widget.bookingId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkOut(GroupBooking booking) async {
    final confirmed = await _showConfirmDialog('Check-out', 'Xác nhận check-out cho đoàn ${booking.name}?');
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupBookingNotifierProvider.notifier).checkOutBooking(booking.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã check-out')));
        ref.invalidate(groupBookingByIdProvider(widget.bookingId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(GroupBooking booking) async {
    final reason = await _showInputDialog('Lý do hủy', 'Nhập lý do hủy đặt phòng');
    if (reason == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupBookingNotifierProvider.notifier).cancelBooking(booking.id, reason: reason);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy')));
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
        title: const Text('Phân phòng'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Số phòng cần: ${booking.roomCount}'),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: controller, decoration: const InputDecoration(labelText: 'Danh sách ID phòng', hintText: 'VD: 1, 2, 3 (ID phòng, cách nhau bằng dấu phẩy)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Lưu')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final roomIds = result.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
    if (roomIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Danh sách phòng không hợp lệ'), backgroundColor: Colors.orange));
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(groupBookingNotifierProvider.notifier).assignRooms(booking.id, roomIds);
      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã phân phòng')));
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
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
      ],
    ));
  }

  Future<String?> _showInputDialog(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xác nhận')),
      ],
    ));
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
