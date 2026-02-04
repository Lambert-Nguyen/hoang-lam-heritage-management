import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/housekeeping.dart';
import '../../providers/auth_provider.dart';
import '../common/app_button.dart';

/// Dialog for assigning a housekeeping task to a staff member
class AssignTaskDialog extends ConsumerStatefulWidget {
  final HousekeepingTask task;

  const AssignTaskDialog({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends ConsumerState<AssignTaskDialog> {
  int? _selectedUserId;
  
  // Mock staff list - in real app, this would come from API
  final List<_StaffMember> _staffList = [
    _StaffMember(id: 1, name: 'Nguyễn Văn A', role: 'Housekeeping'),
    _StaffMember(id: 2, name: 'Trần Thị B', role: 'Housekeeping'),
    _StaffMember(id: 3, name: 'Lê Văn C', role: 'Housekeeping'),
    _StaffMember(id: 4, name: 'Phạm Thị D', role: 'Housekeeping'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.task.assignedTo;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân công công việc',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Phòng ${widget.task.roomNumber ?? widget.task.room}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalLg,

            // Assign to self option
            _buildAssignToSelfOption(),
            AppSpacing.gapVerticalMd,

            const Divider(),
            AppSpacing.gapVerticalMd,

            // Staff list
            Text(
              'Chọn nhân viên',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
            ),
            AppSpacing.gapVerticalSm,

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _staffList.length,
                itemBuilder: (context, index) {
                  final staff = _staffList[index];
                  return _buildStaffTile(staff);
                },
              ),
            ),

            AppSpacing.gapVerticalLg,

            // Action buttons
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
                    label: 'Xác nhận',
                    onPressed: _selectedUserId != null
                        ? () => Navigator.pop(context, _selectedUserId)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignToSelfOption() {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id;

    if (userId == null) return const SizedBox.shrink();

    final isSelected = _selectedUserId == userId;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserId = userId;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              child: Icon(
                Icons.person,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tự nhận việc',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    currentUser?.username ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTile(_StaffMember staff) {
    final isSelected = _selectedUserId == staff.id;

    return ListTile(
      onTap: () {
        setState(() {
          _selectedUserId = staff.id;
        });
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? AppColors.primary
            : AppColors.textSecondary.withValues(alpha: 0.2),
        child: Text(
          staff.name[0],
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        staff.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        staff.role,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  }
}

class _StaffMember {
  final int id;
  final String name;
  final String role;

  _StaffMember({
    required this.id,
    required this.name,
    required this.role,
  });
}
