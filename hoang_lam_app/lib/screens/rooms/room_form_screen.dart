import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
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
  List<String> _getCommonAmenities(BuildContext context) => [
    context.l10n.airConditioning,
    'TV',
    'Wifi',
    context.l10n.safe,
    context.l10n.bathtub,
    context.l10n.hairDryer,
    context.l10n.workDesk,
    context.l10n.balcony,
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
        title: Text(_isEditing ? context.l10n.editRoom : context.l10n.addNewRoom),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: context.l10n.deleteRoom,
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
              decoration: InputDecoration(
                labelText: context.l10n.roomNumberLabel,
                hintText: 'Ví dụ: 101, 102, 201...',
                prefixIcon: const Icon(Icons.meeting_room),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.pleaseEnterRoomNumber;
                }
                return null;
              },
            ),
            
            AppSpacing.gapVerticalMd,
            
            // Room Name (optional)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.roomNameOptional,
                hintText: context.l10n.exampleRoomName,
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            
            AppSpacing.gapVerticalMd,
            
            // Room Type Dropdown
            roomTypesAsync.when(
              data: (roomTypes) => DropdownButtonFormField<int>(
                value: _selectedRoomTypeId,
                decoration: InputDecoration(
                  labelText: '${context.l10n.roomType} *',
                  prefixIcon: const Icon(Icons.category),
                ),
                items: roomTypes.map((type) => DropdownMenuItem(
                  value: type.id,
                  child: Text('${type.name} - ${type.formattedBaseRate}'),
                )).toList(),
                onChanged: (value) => setState(() => _selectedRoomTypeId = value),
                validator: (value) {
                  if (value == null) {
                    return context.l10n.pleaseSelectRoomType;
                  }
                  return null;
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(context.l10n.cannotLoadRoomTypes),
            ),
            
            AppSpacing.gapVerticalMd,
            
            // Floor
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.floor,
                      prefixIcon: const Icon(Icons.stairs),
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
              Text(
                context.l10n.status,
                style: const TextStyle(
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
            Text(
              context.l10n.amenities,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getCommonAmenities(context).map((amenity) => FilterChip(
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
              decoration: InputDecoration(
                labelText: context.l10n.roomNotes,
                hintText: context.l10n.roomNotes,
                prefixIcon: const Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            
            AppSpacing.gapVerticalMd,
            
            // Active Status
            SwitchListTile(
              title: Text(context.l10n.roomIsActive),
              subtitle: Text(
                _isActive 
                  ? context.l10n.roomCanBeBooked 
                  : context.l10n.roomDisabled,
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
              label: Text(_isEditing ? context.l10n.update : context.l10n.addRoom),
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
        // Invalidate room providers so lists refresh
        ref.invalidate(roomsProvider);
        ref.invalidate(allRoomsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
              ? '${context.l10n.roomUpdated} ${result.number}'
              : '${context.l10n.roomAdded} ${result.number}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: ${e.toString()}'),
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
      builder: (dialogContext) => AlertDialog(
        title: Text('${context.l10n.deleteRoom}?'),
        content: Text('${context.l10n.confirmDeleteRoom} ${widget.room?.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteRoom();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.delete),
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
            content: Text('${context.l10n.roomDeleted} ${widget.room!.number}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: ${e.toString()}'),
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
