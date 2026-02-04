import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/housekeeping.dart';
import '../common/app_button.dart';
import '../common/app_input.dart';

/// Dialog for completing a housekeeping task with optional notes
class CompleteTaskDialog extends StatefulWidget {
  final HousekeepingTask task;

  const CompleteTaskDialog({
    super.key,
    required this.task,
  });

  @override
  State<CompleteTaskDialog> createState() => _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends State<CompleteTaskDialog> {
  final _notesController = TextEditingController();
  final List<_ChecklistItem> _checklist = [];

  @override
  void initState() {
    super.initState();
    _initializeChecklist();
  }

  void _initializeChecklist() {
    // Initialize checklist based on task type
    switch (widget.task.taskType) {
      case HousekeepingTaskType.checkoutClean:
        _checklist.addAll([
          _ChecklistItem(label: 'Thay ga giường'),
          _ChecklistItem(label: 'Dọn dẹp phòng tắm'),
          _ChecklistItem(label: 'Hút bụi'),
          _ChecklistItem(label: 'Lau sàn'),
          _ChecklistItem(label: 'Bổ sung đồ dùng'),
          _ChecklistItem(label: 'Kiểm tra minibar'),
        ]);
        break;
      case HousekeepingTaskType.stayClean:
        _checklist.addAll([
          _ChecklistItem(label: 'Dọn dẹp chung'),
          _ChecklistItem(label: 'Thay khăn'),
          _ChecklistItem(label: 'Đổ rác'),
          _ChecklistItem(label: 'Bổ sung nước'),
        ]);
        break;
      case HousekeepingTaskType.deepClean:
        _checklist.addAll([
          _ChecklistItem(label: 'Vệ sinh sâu phòng tắm'),
          _ChecklistItem(label: 'Giặt rèm'),
          _ChecklistItem(label: 'Vệ sinh điều hòa'),
          _ChecklistItem(label: 'Lau kính'),
          _ChecklistItem(label: 'Vệ sinh tủ lạnh'),
          _ChecklistItem(label: 'Kiểm tra nội thất'),
        ]);
        break;
      case HousekeepingTaskType.inspection:
        _checklist.addAll([
          _ChecklistItem(label: 'Kiểm tra độ sạch'),
          _ChecklistItem(label: 'Kiểm tra thiết bị'),
          _ChecklistItem(label: 'Kiểm tra đồ dùng'),
          _ChecklistItem(label: 'Kiểm tra an toàn'),
        ]);
        break;
      case HousekeepingTaskType.maintenance:
        _checklist.addAll([
          _ChecklistItem(label: 'Kiểm tra sự cố'),
          _ChecklistItem(label: 'Thực hiện sửa chữa'),
          _ChecklistItem(label: 'Kiểm tra lại'),
        ]);
        break;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _allItemsChecked => _checklist.every((item) => item.isChecked);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                  ),
                  AppSpacing.gapHorizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hoàn thành công việc',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Phòng ${widget.task.roomNumber ?? widget.task.room}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checklist
                    Text(
                      'Danh sách kiểm tra',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    AppSpacing.gapVerticalSm,
                    ...List.generate(_checklist.length, (index) {
                      return _buildChecklistItem(index);
                    }),
                    AppSpacing.gapVerticalLg,

                    // Notes
                    Text(
                      'Ghi chú (tùy chọn)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    AppSpacing.gapVerticalSm,
                    AppTextField(
                      controller: _notesController,
                      hintText: 'Nhập ghi chú về công việc...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (!_allItemsChecked) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          AppSpacing.gapHorizontalSm,
                          Expanded(
                            child: Text(
                              'Vui lòng hoàn thành tất cả các mục',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.warning,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapVerticalMd,
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Hủy',
                          onPressed: () => Navigator.pop(context),
                          isOutlined: true,
                        ),
                      ),
                      AppSpacing.gapHorizontalMd,
                      Expanded(
                        child: AppButton(
                          label: 'Hoàn thành',
                          onPressed: _allItemsChecked
                              ? () => Navigator.pop(
                                    context,
                                    _notesController.text,
                                  )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(int index) {
    final item = _checklist[index];

    return InkWell(
      onTap: () {
        setState(() {
          item.isChecked = !item.isChecked;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isChecked
                    ? AppColors.success
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isChecked
                      ? AppColors.success
                      : AppColors.divider,
                  width: 2,
                ),
              ),
              child: item.isChecked
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isChecked
                          ? AppColors.textSecondary
                          : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem {
  final String label;
  bool isChecked;

  _ChecklistItem({
    required this.label,
    this.isChecked = false,
  });
}
