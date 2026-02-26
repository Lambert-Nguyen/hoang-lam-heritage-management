import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
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
          _NotificationIconButton(),
          AppIconButton(
            icon: Icons.person_outline,
            onPressed: () {
              context.push(AppRoutes.settings);
            },
            tooltip: context.l10n.account,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(todayBookingsProvider);
          ref.invalidate(roomsProvider);
          // Await the refreshed data so the indicator stays visible
          await ref.read(dashboardSummaryProvider.future);
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
                    todayRevenue: dashboard.today.revenue,
                    todayExpense: dashboard.today.expense,
                  ),
                  AppSpacing.gapVerticalLg,

                  // Occupancy widget
                  DashboardOccupancyWidget(
                    occupancy: dashboard.occupancy,
                    roomStatus: dashboard.roomStatus,
                  ),
                  AppSpacing.gapVerticalLg,

                  // Room status section
                  _buildSectionHeader(context, l10n.roomStatus, Icons.hotel),
                  AppSpacing.gapVerticalMd,
                  _buildRoomGrid(context, ref),
                  AppSpacing.gapVerticalSm,
                  _buildRoomLegend(context),
                  AppSpacing.gapVerticalLg,

                  // Upcoming checkouts
                  _buildSectionHeader(
                    context,
                    l10n.upcomingCheckout,
                    Icons.logout,
                  ),
                  AppSpacing.gapVerticalMd,
                  todayBookingsAsync.when(
                    data: (todayBookings) => _buildUpcomingList(
                      context,
                      ref,
                      todayBookings.checkOuts,
                      isCheckout: true,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('${l10n.error}: $error'),
                  ),
                  AppSpacing.gapVerticalLg,

                  // Upcoming checkins
                  _buildSectionHeader(
                    context,
                    l10n.upcomingCheckin,
                    Icons.login,
                  ),
                  AppSpacing.gapVerticalMd,
                  todayBookingsAsync.when(
                    data: (todayBookings) => _buildUpcomingList(
                      context,
                      ref,
                      todayBookings.checkIns,
                      isCheckout: false,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('${l10n.error}: $error'),
                  ),

                  // Bottom padding for FAB
                  AppSpacing.gapVerticalXl,
                  AppSpacing.gapVerticalXl,
                ],
              ),
            );
          },
          loading: () => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          error: (error, stack) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Center(
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
                          context.l10n.dashboardLoadError,
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
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
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
        label: Text(context.l10n.newBooking),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final now = DateTime.now();
    final locale = context.l10n.locale.languageCode;
    final formatter = DateFormat('EEEE, d MMMM yyyy', locale);

    return Text(
      formatter.format(now),
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    AppLocalizations l10n,
    dashboard,
  ) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: l10n.availableRooms,
            value:
                '${dashboard.roomStatus.available}/${dashboard.roomStatus.total}',
            icon: Icons.hotel,
            color: AppColors.available,
          ),
        ),
        AppSpacing.gapHorizontalMd,
        Expanded(
          child: StatCard(
            label: l10n.checkoutToday,
            value: dashboard.today.pendingDepartures.toString(),
            icon: Icons.logout,
            color: AppColors.occupied,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
        AppSpacing.gapHorizontalSm,
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRoomGrid(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.l10n.noRooms,
              style: const TextStyle(color: AppColors.textHint),
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
                final newStatus = await QuickStatusBottomSheet.show(
                  context,
                  room,
                );
                if (newStatus != null) {
                  await ref
                      .read(roomStateProvider.notifier)
                      .updateRoomStatus(room.id, newStatus);
                  // Refresh dashboard stats after room status change
                  ref.invalidate(dashboardSummaryProvider);
                }
              },
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          '${context.l10n.roomLoadError}: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildRoomLegend(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _buildLegendItem(l10n.available, AppColors.available),
        _buildLegendItem(l10n.occupied, AppColors.occupied),
        _buildLegendItem(l10n.cleaning, AppColors.cleaning),
        _buildLegendItem(l10n.maintenance, AppColors.maintenance),
        _buildLegendItem(l10n.blocked, AppColors.blocked),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.gapHorizontalXs,
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildUpcomingList(
    BuildContext context,
    WidgetRef ref,
    List<Booking> bookings, {
    required bool isCheckout,
  }) {
    final l10n = context.l10n;
    if (bookings.isEmpty) {
      return Padding(
        padding: AppSpacing.paddingVertical,
        child: Text(
          isCheckout ? l10n.noCheckoutToday : l10n.noCheckinToday,
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
                  ? TimeOfDay.fromDateTime(
                      booking.actualCheckOut!,
                    ).format(context)
                  : '${l10n.expectedPrefix}: 12:00')
            : (booking.actualCheckIn != null
                  ? TimeOfDay.fromDateTime(
                      booking.actualCheckIn!,
                    ).format(context)
                  : '${l10n.expectedPrefix}: 14:00');

        final roomNumber = booking.roomNumber ?? booking.room.toString();
        final guestName = booking.guestDetails?.fullName ?? l10n.guest;

        // Show quick action button based on booking status
        final bool canQuickCheckIn =
            !isCheckout &&
            (booking.status == BookingStatus.confirmed ||
                booking.status == BookingStatus.pending);
        final bool canQuickCheckOut =
            isCheckout && booking.status == BookingStatus.checkedIn;

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
                      color: isCheckout
                          ? AppColors.occupied
                          : AppColors.available,
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
                      '${isCheckout ? l10n.checkOut : l10n.checkIn}: $timeStr',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (canQuickCheckIn)
                _QuickActionButton(
                  label: l10n.checkIn,
                  color: AppColors.available,
                  icon: Icons.login,
                  onPressed: () => _showQuickActionDialog(
                    context,
                    ref,
                    booking: booking,
                    isCheckIn: true,
                  ),
                )
              else if (canQuickCheckOut)
                _QuickActionButton(
                  label: l10n.checkOut,
                  color: AppColors.occupied,
                  icon: Icons.logout,
                  onPressed: () => _showQuickActionDialog(
                    context,
                    ref,
                    booking: booking,
                    isCheckIn: false,
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showQuickActionDialog(
    BuildContext context,
    WidgetRef ref, {
    required Booking booking,
    required bool isCheckIn,
  }) async {
    final l10n = context.l10n;
    final roomNumber = booking.roomNumber ?? booking.room.toString();
    final guestName = booking.guestDetails?.fullName ?? l10n.guest;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isCheckIn
              ? l10n.confirmCheckInQuestion
              : l10n.confirmCheckOutQuestion,
        ),
        content: Text(
          (isCheckIn ? l10n.confirmCheckInMessage : l10n.confirmCheckOutMessage)
              .replaceAll('{guestName}', guestName)
              .replaceAll('{roomNumber}', roomNumber),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      if (isCheckIn) {
        await ref.read(bookingNotifierProvider.notifier).checkIn(booking.id);
      } else {
        await ref.read(bookingNotifierProvider.notifier).checkOut(booking.id);
        // Auto-set room to Cleaning after checkout (consistent with detail screen)
        if (booking.room > 0) {
          await ref
              .read(roomStateProvider.notifier)
              .updateRoomStatus(booking.room, RoomStatus.cleaning);
        }
      }

      // Refresh dashboard data
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(todayBookingsProvider);
      ref.invalidate(roomsProvider);

      if (context.mounted) {
        if (isCheckIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.checkedInSuccess)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkoutSuccessViewReceipt),
              action: SnackBarAction(
                label: l10n.viewReceipt,
                onPressed: () {
                  context.push(
                    '${AppRoutes.receipt}/${booking.id}',
                    extra: {
                      'guestName': guestName,
                      'roomNumber': roomNumber,
                    },
                  );
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }
}

/// Notification icon button with unread badge and periodic auto-refresh
class _NotificationIconButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationIconButton> createState() =>
      _NotificationIconButtonState();
}

class _NotificationIconButtonState
    extends ConsumerState<_NotificationIconButton> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh unread count every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      ref.invalidate(unreadNotificationCountProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    return Stack(
      children: [
        AppIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {
            context.push(AppRoutes.notifications);
          },
          tooltip: context.l10n.notifications,
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact action button for quick check-in/check-out on dashboard cards
class _QuickActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
