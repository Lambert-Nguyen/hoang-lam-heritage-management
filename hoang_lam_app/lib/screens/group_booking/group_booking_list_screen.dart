import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/group_booking.dart';
import '../../providers/group_booking_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen for listing group bookings
class GroupBookingListScreen extends ConsumerStatefulWidget {
  const GroupBookingListScreen({super.key});

  @override
  ConsumerState<GroupBookingListScreen> createState() => _GroupBookingListScreenState();
}

class _GroupBookingListScreenState extends ConsumerState<GroupBookingListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  GroupBookingStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _statusFilter = _getStatusFromTabIndex(_tabController.index);
        });
      }
    });
  }

  GroupBookingStatus? _getStatusFromTabIndex(int index) {
    switch (index) {
      case 1: return GroupBookingStatus.confirmed;
      case 2: return GroupBookingStatus.checkedIn;
      case 3: return GroupBookingStatus.checkedOut;
      default: return null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookingsAsync = ref.watch(groupBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupBooking),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [Tab(text: l10n.all), Tab(text: l10n.confirmedStatus), Tab(text: l10n.checkedInStatus), Tab(text: l10n.checkedOutStatus)],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingAll,
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                final filtered = _filterBookings(bookings);
                if (filtered.isEmpty) return _buildEmptyState();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(groupBookingsProvider),
                  child: ListView.builder(
                    padding: AppSpacing.paddingHorizontal,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _GroupBookingCard(
                      booking: filtered[i],
                      onTap: () => context.push('/group-bookings/${filtered[i].id}'),
                    ),
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorDisplay(message: '${l10n.error}: $e', onRetry: () => ref.invalidate(groupBookingsProvider)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/group-bookings/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<GroupBooking> _filterBookings(List<GroupBooking> bookings) {
    return bookings.where((b) {
      if (_statusFilter != null && b.status != _statusFilter) return false;
      if (_searchQuery.isNotEmpty && !b.name.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text('Chưa có đặt phòng đoàn', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _GroupBookingCard extends StatelessWidget {
  final GroupBooking booking;
  final VoidCallback onTap;
  const _GroupBookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(booking.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(color: booking.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(booking.status.icon, size: 14, color: booking.status.color),
                      const SizedBox(width: 4),
                      Text(booking.status.displayName, style: TextStyle(color: booking.status.color, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (booking.contactName.isNotEmpty)
                Row(children: [
                  Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(booking.contactName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  if (booking.contactPhone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(booking.contactPhone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  ],
                ]),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _InfoChip(icon: Icons.calendar_today, label: _formatDateRange(booking.checkInDate, booking.checkOutDate)),
                  const SizedBox(width: 8),
                  _InfoChip(icon: Icons.meeting_room, label: '${booking.roomCount} phòng'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${booking.guestCount} khách', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  Text('${_formatCurrency(booking.totalAmount)}₫', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(String checkIn, String checkOut) {
    try {
      final inDate = DateTime.parse(checkIn);
      final outDate = DateTime.parse(checkOut);
      return '${inDate.day}/${inDate.month} - ${outDate.day}/${outDate.month}';
    } catch (_) {
      return '$checkIn - $checkOut';
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}
