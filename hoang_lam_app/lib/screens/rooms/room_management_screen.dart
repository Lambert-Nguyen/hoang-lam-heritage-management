import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/room.dart';
import '../../providers/room_provider.dart';
import 'room_form_screen.dart';

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
  ConsumerState<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen> {
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phòng'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Ẩn phòng vô hiệu' : 'Hiện phòng vô hiệu',
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
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phòng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildStatChip('Tổng: $totalRooms', AppColors.primary),
                    const SizedBox(width: 8),
                    _buildStatChip('Hoạt động: $activeRooms', AppColors.success),
                    const SizedBox(width: 8),
                    _buildStatChip('Vô hiệu: ${totalRooms - activeRooms}', AppColors.mutedAccent),
                  ],
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
                    final matchesNumber = room.number.toLowerCase().contains(query);
                    final matchesName = room.name?.toLowerCase().contains(query) ?? false;
                    final matchesType = room.roomTypeName?.toLowerCase().contains(query) ?? false;
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
                            ? 'Không tìm thấy phòng'
                            : 'Chưa có phòng nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.gapVerticalMd,
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddRoom(),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm phòng đầu tiên'),
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
                    ref.invalidate(roomsProvider);
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
                              'Tầng $floor',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    AppSpacing.gapVerticalMd,
                    Text('Lỗi: $error'),
                    AppSpacing.gapVerticalMd,
                    ElevatedButton(
                      onPressed: () => ref.invalidate(roomsProvider),
                      child: const Text('Thử lại'),
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
        label: const Text('Thêm phòng'),
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
                color: room.isActive ? room.status.color : AppColors.mutedAccent,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(room.displayName),
            if (!room.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mutedAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Vô hiệu',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Icon(room.status.icon, size: 14, color: room.status.color),
            const SizedBox(width: 4),
            Text(room.status.displayName),
            const SizedBox(width: 12),
            Text(
              room.roomTypeName ?? 'N/A',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
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
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Sửa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: room.isActive ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(room.isActive ? Icons.block : Icons.check_circle),
                title: Text(room.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Xóa', style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToEditRoom(room),
      ),
    );
  }

  void _handleRoomAction(String action, Room room) async {
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

    final result = await ref.read(roomStateProvider.notifier).updateRoom(updatedRoom);
    
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            room.isActive 
              ? 'Đã vô hiệu hóa phòng ${room.number}' 
              : 'Đã kích hoạt phòng ${room.number}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _confirmDeleteRoom(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phòng?'),
        content: Text('Bạn có chắc muốn xóa phòng ${room.number}? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(roomStateProvider.notifier).deleteRoom(room.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa phòng ${room.number}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddRoom() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const RoomFormScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      ref.invalidate(roomsProvider);
    }
  }

  void _navigateToEditRoom(Room room) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RoomFormScreen(room: room),
      ),
    );

    if (result == true) {
      ref.invalidate(roomsProvider);
    }
  }
}
