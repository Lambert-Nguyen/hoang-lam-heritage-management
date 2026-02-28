import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/error_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// Room Management Screen
///
/// Allows owner/manager to:
/// - View all rooms organized by floor
/// - Add new rooms
/// - Edit existing rooms
/// - Delete rooms
/// - Toggle room active status
class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  ConsumerState<RoomManagementScreen> createState() =>
      _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(allRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.roomManagement),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive
                ? context.l10n.hideInactiveRooms
                : context.l10n.showInactiveRooms,
            onPressed: () => setState(() => _showInactive = !_showInactive),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.l10n.searchRooms,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Stats Summary
          roomsAsync.when(
            data: (rooms) {
              final activeRooms = rooms.where((r) => r.isActive).length;
              final totalRooms = rooms.length;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(
                        '${context.l10n.total}: $totalRooms',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        '${context.l10n.active}: $activeRooms',
                        AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        '${context.l10n.inactive}: ${totalRooms - activeRooms}',
                        AppColors.mutedAccent,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Room List
          Expanded(
            child: roomsAsync.when(
              data: (rooms) {
                // Filter rooms
                var filteredRooms = rooms.where((room) {
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final matchesNumber = room.number.toLowerCase().contains(
                      query,
                    );
                    final matchesName =
                        room.name?.toLowerCase().contains(query) ?? false;
                    final matchesType =
                        room.roomTypeName?.toLowerCase().contains(query) ??
                        false;
                    if (!matchesNumber && !matchesName && !matchesType) {
                      return false;
                    }
                  }

                  // Active filter
                  if (!_showInactive && !room.isActive) {
                    return false;
                  }

                  return true;
                }).toList();

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 64,
                          color: AppColors.mutedAccent,
                        ),
                        AppSpacing.gapVerticalMd,
                        Text(
                          _searchQuery.isNotEmpty
                              ? context.l10n.roomNotFound
                              : context.l10n.noRoomsYet,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.gapVerticalMd,
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddRoom(),
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.addFirstRoom),
                        ),
                      ],
                    ),
                  );
                }

                // Group by floor
                final roomsByFloor = <int, List<Room>>{};
                for (final room in filteredRooms) {
                  roomsByFloor.putIfAbsent(room.floor, () => []).add(room);
                }

                final sortedFloors = roomsByFloor.keys.toList()..sort();

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allRoomsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: sortedFloors.length,
                    itemBuilder: (context, index) {
                      final floor = sortedFloors[index];
                      final floorRooms = roomsByFloor[floor]!
                        ..sort((a, b) => a.number.compareTo(b.number));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              '${context.l10n.floor} $floor',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ),
                          ...floorRooms.map((room) => _buildRoomTile(room)),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    AppSpacing.gapVerticalMd,
                    Text(getLocalizedErrorMessage(error, context.l10n)),
                    AppSpacing.gapVerticalMd,
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allRoomsProvider),
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddRoom,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addRoom),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildRoomTile(Room room) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: room.isActive
                ? room.status.color.withValues(alpha: 0.1)
                : AppColors.mutedAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              room.number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: room.isActive
                    ? room.status.color
                    : AppColors.mutedAccent,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(room.displayName, overflow: TextOverflow.ellipsis),
            ),
            if (!room.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mutedAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.l10n.inactive,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Icon(room.status.icon, size: 14, color: room.status.color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                room.status.localizedName(context.l10n),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                room.roomTypeName ?? 'N/A',
                style: TextStyle(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              room.formattedRate,
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleRoomAction(action, room),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: Text(context.l10n.edit),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: room.isActive ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(room.isActive ? Icons.block : Icons.check_circle),
                title: Text(
                  room.isActive
                      ? context.l10n.deactivate
                      : context.l10n.activate,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  context.l10n.delete,
                  style: const TextStyle(color: AppColors.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToEditRoom(room),
      ),
    );
  }

  Future<void> _handleRoomAction(String action, Room room) async {
    switch (action) {
      case 'edit':
        _navigateToEditRoom(room);
        break;
      case 'activate':
      case 'deactivate':
        await _toggleRoomActive(room);
        break;
      case 'delete':
        _confirmDeleteRoom(room);
        break;
    }
  }

  Future<void> _toggleRoomActive(Room room) async {
    final updatedRoom = Room(
      id: room.id,
      number: room.number,
      name: room.name,
      roomTypeId: room.roomTypeId,
      floor: room.floor,
      status: room.status,
      baseRate: room.baseRate,
      amenities: room.amenities,
      notes: room.notes,
      isActive: !room.isActive,
    );

    final result = await ref
        .read(roomStateProvider.notifier)
        .updateRoom(updatedRoom);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            room.isActive
                ? '${context.l10n.roomDeactivated} ${room.number}'
                : '${context.l10n.roomActivated} ${room.number}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _confirmDeleteRoom(Room room) async {
    // Check for active bookings before allowing deletion
    final filter = BookingFilter(
      roomId: room.id,
      status: BookingStatus.confirmed,
    );
    final bookings = await ref.read(filteredBookingsProvider(filter).future).catchError((_) => <Booking>[]);
    final hasActive = bookings.isNotEmpty;

    if (!mounted) return;

    if (hasActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cannotDeleteRoomWithBookings),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${context.l10n.deleteRoom}?'),
        content: Text(
          '${context.l10n.confirmDeleteRoom} ${room.number}? ${context.l10n.actionCannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(roomStateProvider.notifier)
                  .deleteRoom(room.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${context.l10n.roomDeleted} ${room.number}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddRoom() async {
    final result = await context.push<bool>(AppRoutes.roomNew);

    if (result == true) {
      ref.invalidate(allRoomsProvider);
    }
  }

  Future<void> _navigateToEditRoom(Room room) async {
    final result = await context.push<bool>(AppRoutes.roomEdit, extra: room);

    if (result == true) {
      ref.invalidate(allRoomsProvider);
    }
  }
}
