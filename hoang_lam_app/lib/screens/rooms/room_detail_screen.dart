import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/room.dart';
import '../../providers/room_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/rooms/room_status_dialog.dart';

/// Screen showing detailed information about a single room
class RoomDetailScreen extends ConsumerStatefulWidget {
  final Room room;

  const RoomDetailScreen({
    super.key,
    required this.room,
  });

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  late Room _room;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
  }

  Future<void> _changeStatus() async {
    final success = await RoomStatusDialog.show(context, _room);
    if (success == true && mounted) {
      // Refresh room data from provider
      ref.invalidate(roomsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phòng ${_room.number}'),
        actions: [
          AppIconButton(
            icon: Icons.edit,
            onPressed: () {
              // TODO: Navigate to edit room
            },
            tooltip: context.l10n.edit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            _buildStatusHeader(),
            AppSpacing.gapVerticalLg,

            // Room info card
            _buildInfoCard(),
            AppSpacing.gapVerticalLg,

            // Quick actions
            _buildQuickActions(),
            AppSpacing.gapVerticalLg,

            // Notes section
            if (_room.notes != null && _room.notes!.isNotEmpty) ...[
              _buildNotesSection(),
              AppSpacing.gapVerticalLg,
            ],

            // Current booking (if occupied)
            if (_room.status == RoomStatus.occupied) ...[
              _buildCurrentBookingSection(),
              AppSpacing.gapVerticalLg,
            ],

            // Room history
            _buildHistorySection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _room.status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: _room.status.color,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _room.status.icon,
            size: 48,
            color: _room.status.color,
          ),
          AppSpacing.gapVerticalMd,
          Text(
            _room.status.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _room.status.color,
                ),
          ),
          AppSpacing.gapVerticalSm,
          OutlinedButton.icon(
            onPressed: _changeStatus,
            icon: const Icon(Icons.sync),
            label: Text(context.l10n.changeStatus),
            style: OutlinedButton.styleFrom(
              foregroundColor: _room.status.color,
              side: BorderSide(color: _room.status.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.roomInfo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            Icons.door_front_door,
            context.l10n.roomNumber,
            _room.number,
          ),
          _buildInfoRow(
            Icons.stairs,
            context.l10n.floor,
            _room.floor.toString(),
          ),
          _buildInfoRow(
            Icons.hotel,
            context.l10n.roomType,
            _room.roomTypeName ?? context.l10n.undefined,
          ),
          _buildInfoRow(
            Icons.attach_money,
            context.l10n.ratePerNight,
            _room.formattedRate,
          ),
          if (_room.amenities.isNotEmpty)
            _buildInfoRow(
              Icons.wifi,
              context.l10n.amenities,
              _room.amenities.join(', '),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          AppSpacing.gapHorizontalSm,
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.changeStatus,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        AppSpacing.gapVerticalMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _QuickActionChip(
              icon: Icons.check_circle,
              label: context.l10n.available,
              color: AppColors.available,
              isSelected: _room.status == RoomStatus.available,
              onTap: () => _quickStatusChange(RoomStatus.available),
            ),
            _QuickActionChip(
              icon: Icons.person,
              label: context.l10n.occupied,
              color: AppColors.occupied,
              isSelected: _room.status == RoomStatus.occupied,
              onTap: () => _quickStatusChange(RoomStatus.occupied),
            ),
            _QuickActionChip(
              icon: Icons.cleaning_services,
              label: context.l10n.cleaning,
              color: AppColors.cleaning,
              isSelected: _room.status == RoomStatus.cleaning,
              onTap: () => _quickStatusChange(RoomStatus.cleaning),
            ),
            _QuickActionChip(
              icon: Icons.build,
              label: context.l10n.maintenance,
              color: AppColors.maintenance,
              isSelected: _room.status == RoomStatus.maintenance,
              onTap: () => _quickStatusChange(RoomStatus.maintenance),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _quickStatusChange(RoomStatus newStatus) async {
    if (_room.status == newStatus) return;

    final success = await ref.read(roomStateProvider.notifier).updateRoomStatus(
      _room.id,
      newStatus,
    );

    if (success && mounted) {
      setState(() {
        _room = _room.copyWith(status: newStatus);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.roomUpdated} ${_room.number}: ${newStatus.displayName}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildNotesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, size: 20, color: AppColors.textSecondary),
              AppSpacing.gapHorizontalSm,
              Text(
                context.l10n.roomNotes,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Text(
            _room.notes!,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBookingSection() {
    // Placeholder - will be connected to booking provider
    return AppCard(
      color: AppColors.occupied.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.occupied.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.occupied,
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.hasGuests,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      context.l10n.viewBookingDetails,
                      style: const TextStyle(color: AppColors.textSecondary),
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
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.history,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full history
              },
              child: Text(context.l10n.viewAll),
            ),
          ],
        ),
        AppSpacing.gapVerticalSm,
        // Placeholder for history items
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              context.l10n.noHistory,
              style: const TextStyle(color: AppColors.textHint),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                label: context.l10n.bookRoom,
                icon: Icons.book_online,
                onPressed: _room.status == RoomStatus.available
                    ? () {
                        // TODO: Navigate to create booking
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
