import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/room.dart';
import '../../providers/room_provider.dart';
import 'room_status_card.dart';

/// A grid widget displaying all rooms grouped by floor
class RoomGrid extends ConsumerWidget {
  final Function(Room room)? onRoomTap;
  final Function(Room room)? onRoomLongPress;

  const RoomGrid({
    super.key,
    this.onRoomTap,
    this.onRoomLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsByFloorAsync = ref.watch(roomsByFloorProvider);

    return roomsByFloorAsync.when(
      data: (roomsByFloor) {
        if (roomsByFloor.isEmpty) {
          return const _EmptyRoomGrid();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: roomsByFloor.entries.map((entry) {
            return _FloorSection(
              floor: entry.key,
              rooms: entry.value,
              onRoomTap: onRoomTap,
              onRoomLongPress: onRoomLongPress,
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => _ErrorWidget(
        message: context.l10n.cannotLoadRoomList,
        onRetry: () => ref.refresh(roomsByFloorProvider),
      ),
    );
  }
}

/// A section displaying rooms on a single floor
class _FloorSection extends StatelessWidget {
  final int floor;
  final List<Room> rooms;
  final Function(Room room)? onRoomTap;
  final Function(Room room)? onRoomLongPress;

  const _FloorSection({
    required this.floor,
    required this.rooms,
    this.onRoomTap,
    this.onRoomLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            '${context.l10n.floor} $floor',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        // Room cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: rooms.map((room) {
              return RoomStatusCard(
                room: room,
                onTap: onRoomTap != null ? () => onRoomTap!(room) : null,
                onLongPress:
                    onRoomLongPress != null ? () => onRoomLongPress!(room) : null,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// Empty state widget
class _EmptyRoomGrid extends StatelessWidget {
  const _EmptyRoomGrid();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.noRoomsYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Error widget with retry button
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorWidget({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Room status legend widget
class RoomStatusLegend extends StatelessWidget {
  const RoomStatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: RoomStatus.values.map((status) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                status.displayName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Room status summary widget for dashboard
class RoomStatusSummary extends ConsumerWidget {
  const RoomStatusSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusCountsAsync = ref.watch(roomStatusCountsProvider);

    return statusCountsAsync.when(
      data: (counts) {
        final totalRooms = counts.values.fold(0, (sum, count) => sum + count);
        final availableCount = counts[RoomStatus.available] ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.hotel,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.roomStatus,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Main stats
                Row(
                  children: [
                    _StatItem(
                      value: '$availableCount/$totalRooms',
                      label: context.l10n.availableRooms,
                      color: RoomStatus.available.color,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _StatItem(
                      value: '${counts[RoomStatus.occupied] ?? 0}',
                      label: context.l10n.occupied,
                      color: RoomStatus.occupied.color,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _StatItem(
                      value: '${counts[RoomStatus.cleaning] ?? 0}',
                      label: context.l10n.cleaning,
                      color: RoomStatus.cleaning.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
