import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import 'booking_status_badge.dart';

/// Booking Card Widget - Displays booking information in a card
/// 
/// Shows:
/// - Room number and type
/// - Guest name
/// - Check-in/out dates and nights
/// - Booking source and total amount
/// - Status badge
/// 
/// Used in booking lists and calendar views
class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final bool showRoom;
  final bool showGuest;
  final bool compact;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.showRoom = true,
    this.showGuest = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM', 'vi');
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: booking.currency == 'VND' ? 'đ' : booking.currency,
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Room + Status
              Row(
                children: [
                  if (showRoom) ...[
                    Icon(
                      Icons.hotel,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.roomNumber ?? 'Phòng ${booking.room}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                  if (showGuest && showRoom) const SizedBox(width: 8),
                  if (showGuest) ...[
                    Expanded(
                      child: Text(
                        booking.guestName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  BookingStatusBadge(status: booking.status),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Dates and nights
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(booking.checkInDate)} → ${dateFormat.format(booking.checkOutDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_calculateNights(booking.checkInDate, booking.checkOutDate)} đêm',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (!compact) ...[
                const SizedBox(height: 8),
                
                // Source and amount
                Row(
                  children: [
                    _buildSourceChip(context, booking.source),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(booking.totalAmount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                
                // Additional info for specific statuses
                if (booking.status == BookingStatus.pending && booking.depositAmount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đặt cọc: ${currencyFormat.format(booking.depositAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                if (booking.status == BookingStatus.checkedIn && booking.actualCheckIn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Check-in: ${DateFormat('HH:mm dd/MM', 'vi').format(booking.actualCheckIn!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
              
              // Arrow indicator for tap
              if (onTap != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceChip(BuildContext context, BookingSource source) {
    final sourceInfo = _getSourceInfo(source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sourceInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: sourceInfo.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sourceInfo.icon,
            size: 14,
            color: sourceInfo.color,
          ),
          const SizedBox(width: 4),
          Text(
            sourceInfo.label,
            style: TextStyle(
              fontSize: 12,
              color: sourceInfo.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  ({String label, IconData icon, Color color}) _getSourceInfo(BookingSource source) {
    switch (source) {
      case BookingSource.walkIn:
        return (label: 'Walk-in', icon: Icons.directions_walk, color: Colors.blue);
      case BookingSource.phone:
        return (label: 'Điện thoại', icon: Icons.phone, color: Colors.green);
      case BookingSource.bookingCom:
        return (label: 'Booking.com', icon: Icons.public, color: const Color(0xFF003580));
      case BookingSource.agoda:
        return (label: 'Agoda', icon: Icons.public, color: const Color(0xFFEC1C24));
      case BookingSource.airbnb:
        return (label: 'Airbnb', icon: Icons.public, color: const Color(0xFFFF5A5F));
      case BookingSource.traveloka:
        return (label: 'Traveloka', icon: Icons.public, color: const Color(0xFF2D90ED));
      case BookingSource.otherOta:
        return (label: 'OTA khác', icon: Icons.public, color: const Color(0xFF607D8B));
      case BookingSource.website:
        return (label: 'Website', icon: Icons.language, color: Colors.purple);
      case BookingSource.other:
        return (label: 'Khác', icon: Icons.more_horiz, color: Colors.grey);
    }
  }

  int _calculateNights(DateTime checkIn, DateTime checkOut) {
    return checkOut.difference(checkIn).inDays;
  }
}
