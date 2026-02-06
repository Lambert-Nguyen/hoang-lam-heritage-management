import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/bookings/booking_card.dart';
import 'booking_form_screen.dart';
import 'booking_detail_screen.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  DateTime _selectedDate = DateTime.now();
  BookingStatus? _selectedStatus;
  BookingSource? _selectedSource;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Build filter for provider
    final filter = BookingFilter(
      status: _selectedStatus,
      source: _selectedSource,
      startDate: _searchQuery.isEmpty ? _getMonthStart() : null,
      endDate: _searchQuery.isEmpty ? _getMonthEnd() : null,
      ordering: '-check_in_date',
    );

    // Watch filtered bookings
    final bookingsAsync = ref.watch(filteredBookingsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đặt phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(filteredBookingsProvider(filter)),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mini calendar
          _buildMiniCalendar(),
          
          // Filter chips
          _buildFilterChips(),
          
          // Search bar
          _buildSearchBar(),

          const Divider(height: 1),

          // Bookings list
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                final filteredBookings = _applySearchFilter(bookings);
                
                if (filteredBookings.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(filteredBookingsProvider(filter));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return BookingCard(
                        booking: booking,
                        onTap: () => _navigateToDetail(booking),
                        showRoom: true,
                        showGuest: true,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi tải dữ liệu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(filteredBookingsProvider(filter)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateBooking(),
        icon: const Icon(Icons.add),
        label: const Text('Đặt phòng mới'),
      ),
    );
  }

  Widget _buildMiniCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'vi').format(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month - 1,
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Tất cả'),
              selected: _selectedStatus == null,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = null;
                });
              },
            ),
            const SizedBox(width: 8),
            ...BookingStatus.values.map((status) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status.displayName),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? status : null;
                    });
                  },
                  avatar: Icon(
                    status.icon,
                    size: 16,
                    color: _selectedStatus == status
                        ? Colors.white
                        : status.color,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm theo tên khách, số phòng...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có đặt phòng',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có đặt phòng nào cho bộ lọc này',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  List<Booking> _applySearchFilter(List<Booking> bookings) {
    if (_searchQuery.isEmpty) return bookings;

    final query = _searchQuery.toLowerCase();
    return bookings.where((booking) {
      return booking.guestName.toLowerCase().contains(query) ||
          (booking.roomNumber?.toLowerCase().contains(query) ?? false) ||
          booking.id.toString().contains(query);
    }).toList();
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc nâng cao'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trạng thái',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedStatus = null;
                        });
                      },
                    ),
                    ...BookingStatus.values.map((status) {
                      return ChoiceChip(
                        label: Text(status.displayName),
                        selected: _selectedStatus == status,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedStatus = selected ? status : null;
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nguồn đặt phòng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _selectedSource == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedSource = null;
                        });
                      },
                    ),
                    ...BookingSource.values.map((source) {
                      return ChoiceChip(
                        label: Text(source.displayName),
                        selected: _selectedSource == source,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedSource = selected ? source : null;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedSource = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ).then((_) {
      // Trigger rebuild after dialog closes
      setState(() {});
    });
  }

  void _navigateToDetail(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(bookingId: booking.id),
      ),
    );
  }

  void _navigateToCreateBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookingFormScreen(),
      ),
    );
  }

  DateTime _getMonthStart() {
    return DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  DateTime _getMonthEnd() {
    return DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
  }
}
