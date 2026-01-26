import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/room.dart';
import '../../providers/room_provider.dart';

/// Dialog for updating room status
class RoomStatusDialog extends ConsumerStatefulWidget {
  final Room room;

  const RoomStatusDialog({
    super.key,
    required this.room,
  });

  /// Show the dialog and return the selected status
  static Future<bool?> show(BuildContext context, Room room) {
    return showDialog<bool>(
      context: context,
      builder: (context) => RoomStatusDialog(room: room),
    );
  }

  @override
  ConsumerState<RoomStatusDialog> createState() => _RoomStatusDialogState();
}

class _RoomStatusDialogState extends ConsumerState<RoomStatusDialog> {
  late RoomStatus _selectedStatus;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.room.status;
    _notesController.text = widget.room.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              widget.room.number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text('Cập nhật trạng thái'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status
            Text(
              'Trạng thái hiện tại: ${widget.room.status.displayName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.room.status.color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Status options
            Text(
              'Chọn trạng thái mới:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),

            ...RoomStatus.values.map((status) {
              final isSelected = _selectedStatus == status;
              final isCurrentStatus = widget.room.status == status;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Material(
                  color: isSelected
                      ? status.color.withAlpha(30)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: InkWell(
                    onTap: _isLoading ? null : () {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status.icon,
                            color: status.color,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.displayName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: status.color,
                                  ),
                                ),
                                if (isCurrentStatus)
                                  Text(
                                    '(hiện tại)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: status.color,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.md),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Nhập ghi chú...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedStatus == widget.room.status
              ? null
              : _updateStatus,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cập nhật'),
        ),
      ],
    );
  }

  Future<void> _updateStatus() async {
    setState(() {
      _isLoading = true;
    });

    final roomNotifier = ref.read(roomStateProvider.notifier);
    final success = await roomNotifier.updateRoomStatus(
      widget.room.id,
      _selectedStatus,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật phòng ${widget.room.number} thành ${_selectedStatus.displayName}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật trạng thái phòng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Quick status update bottom sheet
class QuickStatusBottomSheet extends ConsumerWidget {
  final Room room;

  const QuickStatusBottomSheet({
    super.key,
    required this.room,
  });

  static Future<RoomStatus?> show(BuildContext context, Room room) {
    return showModalBottomSheet<RoomStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => QuickStatusBottomSheet(room: room),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              'Phòng ${room.number}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Hiện tại: ${room.status.displayName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: room.status.color,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Status options
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: RoomStatus.values.map((status) {
                final isCurrentStatus = room.status == status;

                return ActionChip(
                  avatar: Icon(
                    status.icon,
                    size: 18,
                    color: isCurrentStatus ? Colors.white : status.color,
                  ),
                  label: Text(status.displayName),
                  backgroundColor: isCurrentStatus
                      ? status.color
                      : status.color.withAlpha(30),
                  labelStyle: TextStyle(
                    color: isCurrentStatus ? Colors.white : status.color,
                  ),
                  onPressed: isCurrentStatus
                      ? null
                      : () => Navigator.pop(context, status),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
