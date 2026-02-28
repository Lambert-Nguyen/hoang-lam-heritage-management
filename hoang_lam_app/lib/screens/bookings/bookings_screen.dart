import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error_utils.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/bookings/booking_card.dart';
import '../../l10n/app_localizations.dart';

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
        title: Text(context.l10n.bookingList),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_month),
            tooltip: context.l10n.calendarView,
            onPressed: () => context.go(AppRoutes.bookingCalendar),
          ),
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
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(filteredBookingsProvider(filter));
                    },
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _buildEmptyState(),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(filteredBookingsProvider(filter));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.dataLoadError,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getLocalizedErrorMessage(error, context.l10n),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(filteredBookingsProvider(filter)),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.retry),
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
        label: Text(context.l10n.newBooking),
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
            color: AppColors.deepAccent.withValues(alpha: 0.05),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              label: Text(context.l10n.all),
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
                  label: Text(status.localizedName(context.l10n)),
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
          hintText: context.l10n.searchGuestRoom,
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            context.l10n.noBookings,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.noBookingsForFilter,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.advancedFilter),
        content: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.status,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(context.l10n.all),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedStatus = null;
                        });
                      },
                    ),
                    ...BookingStatus.values.map((status) {
                      return ChoiceChip(
                        label: Text(status.localizedName(context.l10n)),
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
                Text(
                  context.l10n.bookingSource,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(context.l10n.all),
                      selected: _selectedSource == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedSource = null;
                        });
                      },
                    ),
                    ...BookingSource.values.map((source) {
                      return ChoiceChip(
                        label: Text(source.localizedName(context.l10n)),
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
              Navigator.pop(dialogContext);
            },
            child: Text(context.l10n.clearFilter),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    ).then((_) {
      // Trigger rebuild after dialog closes
      setState(() {});
    });
  }

  void _navigateToDetail(Booking booking) {
    context.push('${AppRoutes.bookings}/${booking.id}');
  }

  void _navigateToCreateBooking() {
    context.push(AppRoutes.newBooking);
  }

  DateTime _getMonthStart() {
    return DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  DateTime _getMonthEnd() {
    return DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
  }
}
