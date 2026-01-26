import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_card.dart';

/// Bookings screen with calendar and list
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookings),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Show search
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // TODO: Show full calendar
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mini calendar
          _buildMiniCalendar(context),

          // Filter chips
          _buildFilterChips(context),

          // Booking list
          Expanded(
            child: _buildBookingList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to new booking
        },
        icon: const Icon(Icons.add),
        label: const Text('Đặt phòng'),
      ),
    );
  }

  Widget _buildMiniCalendar(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      return now.add(Duration(days: i - 3));
    });

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          // Month/Year header
          Padding(
            padding: AppSpacing.paddingHorizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                    });
                  },
                ),
                Text(
                  'Tháng ${_selectedDate.month}, ${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 7));
                    });
                  },
                ),
              ],
            ),
          ),
          AppSpacing.gapVerticalSm,

          // Days row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: days.map((day) {
              final isSelected = day.day == _selectedDate.day &&
                  day.month == _selectedDate.month;
              final isToday = day.day == now.day &&
                  day.month == now.month &&
                  day.year == now.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
                child: Container(
                  width: 44,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : null,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(day.weekday),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapVerticalXs,
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return names[weekday - 1];
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      ('all', 'Tất cả'),
      ('checked_in', 'Đang ở'),
      ('upcoming', 'Sắp đến'),
      ('checked_out', 'Đã trả'),
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _filterStatus == filter.$1;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(filter.$2),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filterStatus = filter.$1;
                  });
                },
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context) {
    // Sample data - will be replaced with actual data
    final bookings = [
      _BookingItem(
        roomNumber: '102',
        guestName: 'Nguyễn Văn C',
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 2)),
        source: 'Booking.com',
        amount: 1200000,
        status: 'check_in',
      ),
      _BookingItem(
        roomNumber: '103',
        guestName: 'Trần Thị B',
        checkIn: DateTime.now().subtract(const Duration(days: 2)),
        checkOut: DateTime.now(),
        source: 'Walk-in',
        amount: 800000,
        status: 'check_out',
      ),
      _BookingItem(
        roomNumber: '201',
        guestName: 'Lê Văn D',
        checkIn: DateTime.now().subtract(const Duration(days: 1)),
        checkOut: DateTime.now().add(const Duration(days: 3)),
        source: 'Agoda',
        amount: 2400000,
        status: 'checked_in',
      ),
    ];

    return ListView.builder(
      padding: AppSpacing.paddingScreen,
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(context, booking);
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, _BookingItem booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () {
        // TODO: Navigate to booking detail
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                booking.source,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    booking.roomNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.guestName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${booking.checkIn.day}/${booking.checkIn.month} → ${booking.checkOut.day}/${booking.checkOut.month}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.formatCompact(booking.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'check_in':
        return AppColors.available;
      case 'check_out':
        return AppColors.occupied;
      case 'checked_in':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'check_in':
        return 'Check-in';
      case 'check_out':
        return 'Check-out';
      case 'checked_in':
        return 'Đang ở';
      default:
        return status;
    }
  }
}

class _BookingItem {
  final String roomNumber;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final String source;
  final num amount;
  final String status;

  _BookingItem({
    required this.roomNumber,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.source,
    required this.amount,
    required this.status,
  });
}
