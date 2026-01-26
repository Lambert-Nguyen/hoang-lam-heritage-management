import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/dashboard/dashboard_revenue_card.dart';
import '../../widgets/dashboard/dashboard_occupancy_widget.dart';
import '../../widgets/rooms/room_status_card.dart';
import '../../widgets/rooms/room_status_dialog.dart';

/// Home/Dashboard screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dashboardAsync = ref.watch(dashboardSummaryProvider);
    final todayBookingsAsync = ref.watch(todayBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.hotelName),
        actions: [
          AppIconButton(
            icon: Icons.notifications_outlined,
            onPressed: () {
              // TODO: Show notifications
            },
            tooltip: 'Thông báo',
          ),
          AppIconButton(
            icon: Icons.person_outline,
            onPressed: () {
              context.push(AppRoutes.settings);
            },
            tooltip: 'Tài khoản',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(todayBookingsProvider);
          ref.invalidate(roomsProvider);
        },
        child: dashboardAsync.when(
          data: (dashboard) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's date
                  _buildDateHeader(context),
                  AppSpacing.gapVerticalMd,

                  // Quick stats row
                  _buildQuickStats(context, l10n, dashboard),
                  AppSpacing.gapVerticalLg,

                  // Today's revenue (if financial data available)
                  DashboardRevenueCard(
                    todaySummary: dashboard.today,
                    todayRevenue: 0, // TODO: Get from financial endpoint
                    todayExpense: 0,
                  ),
                  AppSpacing.gapVerticalLg,

                  // Occupancy widget
                  DashboardOccupancyWidget(
                    occupancy: dashboard.occupancy,
                    roomStatus: dashboard.roomStatus,
                  ),
                  AppSpacing.gapVerticalLg,

                  // Room status section
                  _buildSectionHeader(context, 'Trạng thái phòng', Icons.hotel),
                  AppSpacing.gapVerticalMd,
                  _buildRoomGrid(context, ref),
                  AppSpacing.gapVerticalSm,
                  _buildRoomLegend(context),
                  AppSpacing.gapVerticalLg,

                  // Upcoming checkouts
                  _buildSectionHeader(context, 'Sắp check-out', Icons.logout),
                  AppSpacing.gapVerticalMd,
                  todayBookingsAsync.when(
                    data: (todayBookings) => _buildUpcomingList(
                      context,
                      todayBookings.checkOuts,
                      isCheckout: true,
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Text('Lỗi: $error'),
                  ),
                  AppSpacing.gapVerticalLg,

                  // Upcoming checkins
                  _buildSectionHeader(context, 'Sắp check-in', Icons.login),
                  AppSpacing.gapVerticalMd,
                  todayBookingsAsync.when(
                    data: (todayBookings) => _buildUpcomingList(
                      context,
                      todayBookings.checkIns,
                      isCheckout: false,
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Text('Lỗi: $error'),
                  ),

                  // Bottom padding for FAB
                  AppSpacing.gapVerticalXl,
                  AppSpacing.gapVerticalXl,
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: AppSpacing.paddingScreen,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  AppSpacing.gapVerticalMd,
                  Text(
                    'Không thể tải dữ liệu dashboard',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AppSpacing.gapVerticalSm,
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapVerticalMd,
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(dashboardSummaryProvider);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.newBooking);
        },
        icon: const Icon(Icons.add),
        label: const Text('Đặt phòng'),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM yyyy', 'vi');

    return Text(
      formatter.format(now),
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppLocalizations l10n, dashboard) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Phòng trống',
            value: '${dashboard.roomStatus.available}/${dashboard.roomStatus.total}',
            icon: Icons.hotel,
            color: AppColors.available,
          ),
        ),
        AppSpacing.gapHorizontalMd,
        Expanded(
          child: StatCard(
            label: 'Check-out hôm nay',
            value: dashboard.today.pendingDepartures.toString(),
            icon: Icons.logout,
            color: AppColors.occupied,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
        AppSpacing.gapHorizontalSm,
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomGrid(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Chưa có phòng nào',
              style: TextStyle(color: AppColors.textHint),
            ),
          );
        }

        return Wrap(
          spacing: AppSpacing.roomCardSpacing,
          runSpacing: AppSpacing.roomCardSpacing,
          children: rooms.map((room) {
            return RoomStatusCard(
              room: room,
              onTap: () {
                // Navigate to room detail
                context.push(AppRoutes.roomDetail, extra: room);
              },
              onLongPress: () async {
                // Show quick status update
                final newStatus = await QuickStatusBottomSheet.show(context, room);
                if (newStatus != null) {
                  ref.read(roomStateProvider.notifier).updateRoomStatus(
                    room.id,
                    newStatus,
                  );
                }
              },
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Lỗi tải dữ liệu phòng: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildRoomLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Trống', AppColors.available),
        AppSpacing.gapHorizontalMd,
        _buildLegendItem('Có khách', AppColors.occupied),
        AppSpacing.gapHorizontalMd,
        _buildLegendItem('Dọn dẹp', AppColors.cleaning),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        AppSpacing.gapHorizontalXs,
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingList(
    BuildContext context,
    List<Booking> bookings, {
    required bool isCheckout,
  }) {
    if (bookings.isEmpty) {
      return Padding(
        padding: AppSpacing.paddingVertical,
        child: Text(
          isCheckout ? 'Không có check-out hôm nay' : 'Không có check-in hôm nay',
          style: const TextStyle(
            color: AppColors.textHint,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: bookings.map((booking) {
        final timeStr = isCheckout
            ? (booking.actualCheckOut != null
                ? TimeOfDay.fromDateTime(booking.actualCheckOut!).format(context)
                : '12:00')
            : (booking.actualCheckIn != null
                ? TimeOfDay.fromDateTime(booking.actualCheckIn!).format(context)
                : '14:00');

        final roomNumber = booking.roomNumber ?? booking.room.toString();
        final guestName = booking.guestDetails?.fullName ?? 'Khách';

        return AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          onTap: () {
            context.push('${AppRoutes.bookings}/${booking.id}');
          },
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isCheckout ? AppColors.occupied : AppColors.available)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    roomNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCheckout ? AppColors.occupied : AppColors.available,
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
                      guestName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${isCheckout ? "Check-out" : "Check-in"}: $timeStr',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
