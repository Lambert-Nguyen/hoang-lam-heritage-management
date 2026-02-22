import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/bookings/booking_card.dart';
import 'booking_detail_screen.dart';
import 'booking_form_screen.dart';
import '../../core/theme/app_colors.dart';

/// Booking Calendar Screen - Phase 1.9.4
///
/// Main booking management screen with calendar view showing:
/// - Monthly calendar with booking indicators
/// - List of bookings for selected date
/// - Filter options (all, check-in, check-out, staying)
/// - FAB for creating new bookings
///
/// Follows design plan mockup from docs/HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md
class BookingCalendarScreen extends ConsumerStatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  ConsumerState<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends ConsumerState<BookingCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _filterType = 'all'; // all, check_in, check_out, staying

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = DateRange(
      start: DateTime(_focusedDay.year, _focusedDay.month, 1),
      end: DateTime(_focusedDay.year, _focusedDay.month + 1, 0),
    );

    final calendarBookingsAsync = ref.watch(
      calendarBookingsProvider(dateRange),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bookings),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.go(AppRoutes.bookings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar widget
          calendarBookingsAsync.when(
            data: (bookings) => _buildCalendar(bookings),
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            error:
                (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('${context.l10n.error}: $error'),
                  ),
                ),
          ),

          const Divider(height: 1),

          // Filter chips
          _buildFilterChips(),

          const Divider(height: 1),

          // Bookings for selected day
          Expanded(child: _buildBookingsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BookingFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newBooking),
      ),
    );
  }

  Widget _buildCalendar(List<Booking> bookings) {
    // Create a map of dates to bookings for event markers
    final Map<DateTime, List<Booking>> bookingsByDate = {};
    for (final booking in bookings) {
      final checkInDate = DateTime(
        booking.checkInDate.year,
        booking.checkInDate.month,
        booking.checkInDate.day,
      );
      final checkOutDate = DateTime(
        booking.checkOutDate.year,
        booking.checkOutDate.month,
        booking.checkOutDate.day,
      );

      // Add booking to check-in date
      bookingsByDate.putIfAbsent(checkInDate, () => []).add(booking);

      // Add to intermediate dates if staying multiple nights
      DateTime currentDate = checkInDate.add(const Duration(days: 1));
      while (currentDate.isBefore(checkOutDate)) {
        bookingsByDate.putIfAbsent(currentDate, () => []).add(booking);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: TableCalendar<Booking>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          return bookingsByDate[normalizedDay] ?? [];
        },
        calendarStyle: CalendarStyle(
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildFilterChip(context.l10n.all, 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(context.l10n.checkIn, 'check_in'),
          const SizedBox(width: 8),
          _buildFilterChip(context.l10n.checkOut, 'check_out'),
          const SizedBox(width: 8),
          _buildFilterChip(context.l10n.occupied, 'staying'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterType) {
    final isSelected = _filterType == filterType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = filterType;
        });
      },
    );
  }

  Widget _buildBookingsList() {
    if (_selectedDay == null) {
      return Center(child: Text(context.l10n.selectBooking));
    }

    final dateRange = DateRange(
      start: DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      ),
      end: DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        23,
        59,
        59,
      ),
    );

    final bookingsAsync = ref.watch(calendarBookingsProvider(dateRange));

    return bookingsAsync.when(
      data: (bookings) {
        // Filter bookings based on selected filter type
        final filteredBookings = _filterBookings(bookings);

        if (filteredBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: AppColors.mutedAccent),
                const SizedBox(height: 16),
                Text(
                  context.l10n.noBookings,
                  style: TextStyle(fontSize: 16, color: AppColors.mutedAccent),
                ),
                Text(
                  DateFormat('dd/MM/yyyy', 'vi').format(_selectedDay!),
                  style: TextStyle(fontSize: 14, color: AppColors.mutedAccent),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${context.l10n.bookingDate}: ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // Bookings grouped by type
            ..._buildGroupedBookings(filteredBookings),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
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
                  Text('${context.l10n.error}: $error'),
                ],
              ),
            ),
          ),
    );
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    if (_selectedDay == null) return bookings;

    final selectedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    return bookings.where((booking) {
      final checkInDate = DateTime(
        booking.checkInDate.year,
        booking.checkInDate.month,
        booking.checkInDate.day,
      );
      final checkOutDate = DateTime(
        booking.checkOutDate.year,
        booking.checkOutDate.month,
        booking.checkOutDate.day,
      );

      switch (_filterType) {
        case 'check_in':
          return isSameDay(checkInDate, selectedDate);
        case 'check_out':
          return isSameDay(checkOutDate, selectedDate);
        case 'staying':
          return booking.status == BookingStatus.checkedIn &&
              (selectedDate.isAfter(checkInDate) ||
                  isSameDay(checkInDate, selectedDate)) &&
              selectedDate.isBefore(checkOutDate);
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  List<Widget> _buildGroupedBookings(List<Booking> bookings) {
    if (_selectedDay == null) return [];

    final selectedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    final checkIns = <Booking>[];
    final checkOuts = <Booking>[];
    final staying = <Booking>[];

    for (final booking in bookings) {
      final checkInDate = DateTime(
        booking.checkInDate.year,
        booking.checkInDate.month,
        booking.checkInDate.day,
      );
      final checkOutDate = DateTime(
        booking.checkOutDate.year,
        booking.checkOutDate.month,
        booking.checkOutDate.day,
      );

      if (isSameDay(checkInDate, selectedDate)) {
        checkIns.add(booking);
      } else if (isSameDay(checkOutDate, selectedDate)) {
        checkOuts.add(booking);
      } else if (booking.status == BookingStatus.checkedIn) {
        staying.add(booking);
      }
    }

    final widgets = <Widget>[];

    // Check-ins
    if (checkIns.isNotEmpty &&
        (_filterType == 'all' || _filterType == 'check_in')) {
      widgets.add(
        _buildGroupHeader('🟢 ${context.l10n.checkIn}', checkIns.length),
      );
      widgets.addAll(
        checkIns.map(
          (b) =>
              BookingCard(booking: b, onTap: () => _navigateToBookingDetail(b)),
        ),
      );
    }

    // Check-outs
    if (checkOuts.isNotEmpty &&
        (_filterType == 'all' || _filterType == 'check_out')) {
      widgets.add(
        _buildGroupHeader('🔴 ${context.l10n.checkOut}', checkOuts.length),
      );
      widgets.addAll(
        checkOuts.map(
          (b) =>
              BookingCard(booking: b, onTap: () => _navigateToBookingDetail(b)),
        ),
      );
    }

    // Staying
    if (staying.isNotEmpty &&
        (_filterType == 'all' || _filterType == 'staying')) {
      widgets.add(
        _buildGroupHeader('🔵 ${context.l10n.occupied}', staying.length),
      );
      widgets.addAll(
        staying.map(
          (b) =>
              BookingCard(booking: b, onTap: () => _navigateToBookingDetail(b)),
        ),
      );
    }

    return widgets;
  }

  Widget _buildGroupHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBookingDetail(Booking booking) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(bookingId: booking.id),
      ),
    );
  }

  void _showFilterDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.filter),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterOption(ctx, l10n.all, 'all'),
                _buildFilterOption(ctx, 'Check-in', 'check_in'),
                _buildFilterOption(ctx, 'Check-out', 'check_out'),
                _buildFilterOption(ctx, l10n.staying, 'staying'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
    );
  }

  Widget _buildFilterOption(BuildContext ctx, String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _filterType,
      onChanged: (v) {
        setState(() => _filterType = v!);
        Navigator.of(ctx).pop();
      },
    );
  }
}
