import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/housekeeping.dart';
import '../../models/room.dart';
import '../../providers/housekeeping_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_dropdown.dart';
import '../../widgets/common/app_text_field.dart';

/// Screen for creating or editing a housekeeping task
class TaskFormScreen extends ConsumerStatefulWidget {
  final HousekeepingTask? task;

  const TaskFormScreen({
    super.key,
    this.task,
  });

  bool get isEditing => task != null;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  late int? _selectedRoomId;
  late HousekeepingTaskType _selectedTaskType;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.task?.room;
    _selectedTaskType = widget.task?.taskType ?? HousekeepingTaskType.stayClean;
    _selectedDate = widget.task?.scheduledDate ?? DateTime.now();
    _notesController.text = widget.task?.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Sửa công việc' : 'Tạo công việc'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room selection
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    roomsAsync.when(
                      data: (response) => _buildRoomDropdown(response.results),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => Text(
                        'Không thể tải danh sách phòng',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Task type selection
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loại công việc',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    _buildTaskTypeSelector(),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Scheduled date
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày dự kiến',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    _buildDatePicker(),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Notes
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi chú',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    AppTextField(
                      controller: _notesController,
                      hintText: 'Nhập ghi chú (tùy chọn)',
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalLg,

              // Submit button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: widget.isEditing ? 'Cập nhật' : 'Tạo công việc',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomDropdown(List<Room> rooms) {
    return AppDropdown<int>(
      value: _selectedRoomId,
      items: rooms
          .map((room) => DropdownMenuItem(
                value: room.id,
                child: Text('Phòng ${room.roomNumber}'),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedRoomId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Vui lòng chọn phòng';
        }
        return null;
      },
      hint: 'Chọn phòng',
    );
  }

  Widget _buildTaskTypeSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: HousekeepingTaskType.values.map((type) {
        final isSelected = type == _selectedTaskType;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedTaskType = type;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? type.color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? type.color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: 20,
                  color: isSelected ? type.color : AppColors.textSecondary,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  type.displayName,
                  style: TextStyle(
                    color: isSelected ? type.color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
            AppSpacing.gapHorizontalMd,
            Text(
              dateFormat.format(_selectedDate),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi', 'VN'),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);

      HousekeepingTask? result;
      if (widget.isEditing) {
        result = await notifier.updateTask(
          widget.task!.id,
          HousekeepingTaskUpdate(
            room: _selectedRoomId,
            taskType: _selectedTaskType.apiValue,
            scheduledDate: _selectedDate,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          ),
        );
      } else {
        result = await notifier.createTask(
          HousekeepingTaskCreate(
            room: _selectedRoomId!,
            taskType: _selectedTaskType.apiValue,
            scheduledDate: _selectedDate,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          ),
        );
      }

      if (result != null && mounted) {
        Navigator.pop(context, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Đã cập nhật công việc'
                  : 'Đã tạo công việc mới',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
