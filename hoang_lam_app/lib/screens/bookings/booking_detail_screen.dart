import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/bookings/booking_status_badge.dart';
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
        title: const Text('Chi tiết đặt phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              bookingAsync.whenData((booking) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookingFormScreen(booking: booking),
                  ),
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, ref),
          ),
        ],
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
                Text('Lỗi: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Quay lại'),
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
                  booking.roomNumber ?? 'Phòng ${booking.room}',
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
            title: '👤 Thông tin khách',
            children: [
              _buildInfoRow('Tên', booking.guestName),
              if (booking.guestPhone.isNotEmpty)
                _buildInfoRow('SĐT', booking.guestPhone),
              _buildInfoRow('Số khách', '${booking.guestCount} người'),
            ],
          ),

          // Dates and Times
          _buildSection(
            context,
            title: '📅 Thời gian',
            children: [
              _buildInfoRow(
                'Check-in dự kiến',
                '${dateFormat.format(booking.checkInDate)} ${DateFormat('HH:mm').format(booking.checkInDate)}',
              ),
              _buildInfoRow(
                'Check-out dự kiến',
                '${dateFormat.format(booking.checkOutDate)} ${DateFormat('HH:mm').format(booking.checkOutDate)}',
              ),
              _buildInfoRow(
                'Số đêm',
                '${booking.checkOutDate.difference(booking.checkInDate).inDays} đêm',
              ),
              if (booking.actualCheckIn != null)
                _buildInfoRow(
                  'Check-in thực tế',
                  dateTimeFormat.format(booking.actualCheckIn!),
                  highlight: true,
                ),
              if (booking.actualCheckOut != null)
                _buildInfoRow(
                  'Check-out thực tế',
                  dateTimeFormat.format(booking.actualCheckOut!),
                  highlight: true,
                ),
            ],
          ),

          // Payment Information
          _buildSection(
            context,
            title: '💰 Thanh toán',
            children: [
              _buildInfoRow(
                'Giá/đêm',
                currencyFormat.format(booking.nightlyRate),
              ),
              _buildInfoRow(
                'Tổng tiền',
                currencyFormat.format(booking.totalAmount),
                bold: true,
              ),
              if (booking.depositAmount > 0) ...[
                _buildInfoRow(
                  'Đã đặt cọc',
                  currencyFormat.format(booking.depositAmount),
                  valueColor: Colors.green,
                ),
                _buildInfoRow(
                  'Còn lại',
                  currencyFormat.format(booking.totalAmount - booking.depositAmount),
                  valueColor: Colors.orange,
                ),
              ],
              _buildInfoRow(
                'Phương thức',
                _getPaymentMethodLabel(booking.paymentMethod),
              ),
            ],
          ),

          // Booking Source and Notes
          _buildSection(
            context,
            title: '📋 Thông tin đặt phòng',
            children: [
              _buildInfoRow(
                'Nguồn',
                _getBookingSourceLabel(booking.source),
              ),
              if (booking.createdAt != null)
                _buildInfoRow(
                  'Ngày đặt',
                  dateTimeFormat.format(booking.createdAt!),
                ),
              if (booking.specialRequests.isNotEmpty)
                _buildInfoRow(
                  'Yêu cầu đặc biệt',
                  booking.specialRequests,
                ),
              if (booking.notes.isNotEmpty)
                _buildInfoRow(
                  'Ghi chú nội bộ',
                  booking.notes,
                  valueColor: Colors.grey[600],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              style: TextStyle(
                color: Colors.grey[600],
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
                color: valueColor ?? (highlight ? Colors.blue : Colors.black87),
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
        // Check-in button
        if (booking.status == BookingStatus.confirmed)
          ElevatedButton.icon(
            onPressed: () => _handleCheckIn(context, ref, booking),
            icon: const Icon(Icons.login),
            label: const Text('Check-in'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),

        // Check-out button
        if (booking.status == BookingStatus.checkedIn) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _handleCheckOut(context, ref, booking),
            icon: const Icon(Icons.logout),
            label: const Text('Check-out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
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
            label: const Text('Hủy đặt phòng'),
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
            label: const Text('Đánh dấu không đến'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  String _getBookingSourceLabel(BookingSource source) {
    switch (source) {
      case BookingSource.walkIn:
        return 'Walk-in (Khách vãng lai)';
      case BookingSource.phone:
        return 'Điện thoại';
      case BookingSource.bookingCom:
        return 'Booking.com';
      case BookingSource.agoda:
        return 'Agoda';
      case BookingSource.airbnb:
        return 'Airbnb';
      case BookingSource.traveloka:
        return 'Traveloka';
      case BookingSource.otherOta:
        return 'OTA khác';
      case BookingSource.website:
        return 'Đặt trực tiếp (Website)';
      case BookingSource.other:
        return 'Khác';
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.card:
        return 'Thẻ tín dụng';
      case PaymentMethod.otaCollect:
        return 'OTA thu hộ';
      case PaymentMethod.other:
        return 'Khác';
    }
  }

  void _handleCheckIn(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận check-in'),
        content: Text('Xác nhận check-in cho ${booking.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Check-in'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).checkIn(bookingId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check-in thành công')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  void _handleCheckOut(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận check-out'),
        content: Text('Xác nhận check-out cho ${booking.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Check-out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).checkOut(bookingId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check-out thành công')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  void _handleCancel(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt phòng'),
        content: Text('Bạn có chắc muốn hủy đặt phòng cho ${booking.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đặt phòng'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).cancelBooking(bookingId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy đặt phòng')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  void _handleNoShow(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đánh dấu không đến'),
        content: Text('Đánh dấu ${booking.guestName} không đến (no-show)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingNotifierProvider.notifier).markAsNoShow(bookingId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đánh dấu không đến')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đặt phòng'),
        content: const Text('Bạn có chắc muốn xóa đặt phòng này?\n\nThao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
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
            const SnackBar(content: Text('Đã xóa đặt phòng')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }
}
