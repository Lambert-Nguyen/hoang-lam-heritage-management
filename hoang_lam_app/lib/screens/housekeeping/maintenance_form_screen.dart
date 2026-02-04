import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/housekeeping.dart';
import '../../models/room.dart';
import '../../providers/housekeeping_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';

/// Screen for creating or editing a maintenance request
class MaintenanceFormScreen extends ConsumerStatefulWidget {
  final MaintenanceRequest? request;

  const MaintenanceFormScreen({
    super.key,
    this.request,
  });

  bool get isEditing => request != null;

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedCostController = TextEditingController();

  late int? _selectedRoomId;
  late MaintenanceCategory _selectedCategory;
  late MaintenancePriority _selectedPriority;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.request?.room;
    _selectedCategory = widget.request?.category ?? MaintenanceCategory.other;
    _selectedPriority = widget.request?.priority ?? MaintenancePriority.medium;
    _titleController.text = widget.request?.title ?? '';
    _descriptionController.text = widget.request?.description ?? '';
    if (widget.request?.estimatedCost != null) {
      _estimatedCostController.text =
          widget.request!.estimatedCost!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Sửa yêu cầu' : 'Tạo yêu cầu bảo trì'),
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
                      data: (rooms) => _buildRoomDropdown(rooms),
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

              // Title
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiêu đề',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    AppTextField(
                      controller: _titleController,
                      hint: 'Mô tả ngắn gọn vấn đề',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Category selection
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh mục',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    _buildCategorySelector(),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Priority selection
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mức ưu tiên',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    _buildPrioritySelector(),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Description
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mô tả chi tiết',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    AppTextField(
                      controller: _descriptionController,
                      hint: 'Mô tả chi tiết vấn đề cần xử lý...',
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Estimated cost (optional)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi phí ước tính (tùy chọn)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    AppTextField(
                      controller: _estimatedCostController,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                      helper: 'VNĐ',
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalLg,

              // Submit button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: widget.isEditing ? 'Cập nhật' : 'Tạo yêu cầu',
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
                child: Text('Phòng ${room.number}'),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedRoomId = value;
        });
      },
      hint: 'Chọn phòng',
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: MaintenanceCategory.values.map((category) {
        final isSelected = category == _selectedCategory;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
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
                  ? category.color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? category.color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 18,
                  color:
                      isSelected ? category.color : AppColors.textSecondary,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  category.displayName,
                  style: TextStyle(
                    color:
                        isSelected ? category.color : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: MaintenancePriority.values.map((priority) {
        final isSelected = priority == _selectedPriority;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority != MaintenancePriority.values.last
                  ? AppSpacing.sm
                  : 0,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPriority = priority;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? priority.color.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? priority.color : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      priority.icon,
                      size: 24,
                      color: isSelected
                          ? priority.color
                          : AppColors.textSecondary,
                    ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      priority.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? priority.color
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
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
      
      int? estimatedCost;
      if (_estimatedCostController.text.isNotEmpty) {
        estimatedCost = int.tryParse(_estimatedCostController.text);
      }

      MaintenanceRequest? result;
      if (widget.isEditing) {
        result = await notifier.updateMaintenanceRequest(
          widget.request!.id,
          MaintenanceRequestUpdate(
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory.apiValue,
            priority: _selectedPriority.apiValue,
            estimatedCost: estimatedCost,
          ),
        );
      } else {
        result = await notifier.createMaintenanceRequest(
          MaintenanceRequestCreate(
            room: _selectedRoomId!,
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory.apiValue,
            priority: _selectedPriority.apiValue,
          ),
        );
      }

      if (result != null && mounted) {
        Navigator.pop(context, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Đã cập nhật yêu cầu'
                  : 'Đã tạo yêu cầu bảo trì mới',
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
