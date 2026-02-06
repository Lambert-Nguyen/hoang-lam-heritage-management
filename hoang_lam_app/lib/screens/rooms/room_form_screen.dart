import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/room.dart';
import '../../providers/room_provider.dart';

/// Room Form Screen for creating and editing rooms
/// 
/// Fields:
/// - Room number (required)
/// - Room name (optional)
/// - Room type (required, dropdown) - pricing is determined by room type
/// - Floor (required)
/// - Amenities
/// - Notes
/// - Active status
class RoomFormScreen extends ConsumerStatefulWidget {
  final Room? room; // null for new room

  const RoomFormScreen({super.key, this.room});

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _numberController;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  
  int? _selectedRoomTypeId;
  int _floor = 1;
  bool _isActive = true;
  RoomStatus _status = RoomStatus.available;
  List<String> _amenities = [];
  
  bool _isLoading = false;
  bool get _isEditing => widget.room != null;

  // Common amenities for quick selection
  final List<String> _commonAmenities = [
    'Điều hòa',
    'TV',
    'Wifi',
    'Tủ lạnh',
    'Két sắt',
    'Bồn tắm',
    'Vòi sen',
    'Máy sấy tóc',
    'Bàn làm việc',
    'Ban công',
  ];

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    
    _numberController = TextEditingController(text: room?.number ?? '');
    _nameController = TextEditingController(text: room?.name ?? '');
    _notesController = TextEditingController(text: room?.notes ?? '');
    
    if (room != null) {
      _selectedRoomTypeId = room.roomTypeId;
      _floor = room.floor;
      _isActive = room.isActive;
      _status = room.status;
      _amenities = List.from(room.amenities);
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomTypesAsync = ref.watch(roomTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa phòng' : 'Thêm phòng mới'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Xóa phòng',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Room Number
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Số phòng *',
                hintText: 'Ví dụ: 101, 102, 201...',
                prefixIcon: Icon(Icons.meeting_room),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số phòng';
                }
                return null;
              },
            ),
            
            AppSpacing.gapVerticalMd,
            
            // Room Name (optional)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên phòng (tùy chọn)',
                hintText: 'Ví dụ: Phòng Hướng Biển',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            
            AppSpacing.gapVerticalMd,
            
            // Room Type Dropdown
            roomTypesAsync.when(
              data: (roomTypes) => DropdownButtonFormField<int>(
                value: _selectedRoomTypeId,
                decoration: const InputDecoration(
                  labelText: 'Loại phòng *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: roomTypes.map((type) => DropdownMenuItem(
                  value: type.id,
                  child: Text('${type.name} - ${type.formattedBaseRate}'),
                )).toList(),
                onChanged: (value) => setState(() => _selectedRoomTypeId = value),
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn loại phòng';
                  }
                  return null;
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Không thể tải loại phòng'),
            ),
            
            AppSpacing.gapVerticalMd,
            
            // Floor
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tầng',
                      prefixIcon: Icon(Icons.stairs),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _floor > 1 
                            ? () => setState(() => _floor--) 
                            : null,
                        ),
                        Text(
                          '$_floor',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _floor < 20 
                            ? () => setState(() => _floor++) 
                            : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            AppSpacing.gapVerticalLg,
            
            // Status (only for editing)
            if (_isEditing) ...[
              const Text(
                'Trạng thái',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AppSpacing.gapVerticalSm,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RoomStatus.values.map((status) => ChoiceChip(
                  label: Text(status.displayName),
                  selected: _status == status,
                  selectedColor: status.color.withValues(alpha: 0.3),
                  avatar: Icon(status.icon, size: 18, color: status.color),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _status = status);
                    }
                  },
                )).toList(),
              ),
              AppSpacing.gapVerticalLg,
            ],
            
            // Amenities
            const Text(
              'Tiện nghi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonAmenities.map((amenity) => FilterChip(
                label: Text(amenity),
                selected: _amenities.contains(amenity),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _amenities.add(amenity);
                    } else {
                      _amenities.remove(amenity);
                    }
                  });
                },
              )).toList(),
            ),
            
            AppSpacing.gapVerticalLg,
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ghi chú về phòng...',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            
            AppSpacing.gapVerticalMd,
            
            // Active Status
            SwitchListTile(
              title: const Text('Phòng đang hoạt động'),
              subtitle: Text(
                _isActive 
                  ? 'Phòng có thể được đặt' 
                  : 'Phòng bị vô hiệu hóa',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              secondary: Icon(
                _isActive ? Icons.check_circle : Icons.cancel,
                color: _isActive ? AppColors.success : AppColors.error,
              ),
            ),
            
            AppSpacing.gapVerticalXl,
            
            // Save Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveRoom,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
              label: Text(_isEditing ? 'Cập nhật' : 'Thêm phòng'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            
            AppSpacing.gapVerticalXl,
          ],
        ),
      ),
    );
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomTypeId == null) return;

    setState(() => _isLoading = true);

    try {
      final room = Room(
        id: widget.room?.id ?? 0,
        number: _numberController.text.trim(),
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        roomTypeId: _selectedRoomTypeId!,
        floor: _floor,
        status: _isEditing ? _status : RoomStatus.available,
        amenities: _amenities,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isActive: _isActive,
      );

      final notifier = ref.read(roomStateProvider.notifier);
      
      Room? result;
      if (_isEditing) {
        result = await notifier.updateRoom(room);
      } else {
        result = await notifier.createRoom(room);
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
              ? 'Đã cập nhật phòng ${result.number}' 
              : 'Đã thêm phòng ${result.number}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phòng?'),
        content: Text('Bạn có chắc muốn xóa phòng ${widget.room?.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRoom();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom() async {
    if (widget.room == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(roomStateProvider.notifier).deleteRoom(widget.room!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa phòng ${widget.room!.number}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
