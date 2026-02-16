import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.task.assignedTo;
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

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
                        context.l10n.assignRepair,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${context.l10n.room} ${widget.task.roomNumber ?? widget.task.room}',
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
              context.l10n.selectStaff,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
            ),
            AppSpacing.gapVerticalSm,

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: staffAsync.when(
                data: (staffList) {
                  if (staffList.isEmpty) {
                    return Center(
                      child: Text(context.l10n.noStaffAvailable),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      final staff = staffList[index];
                      return _buildStaffTile(staff);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.errorLoadingStaffList,
                        style: TextStyle(color: AppColors.error),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(staffListProvider),
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            AppSpacing.gapVerticalLg,

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: context.l10n.cancel,
                    onPressed: () => Navigator.pop(context),
                    isOutlined: true,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: AppButton(
                    label: context.l10n.confirm,
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
                    context.l10n.assignToSelf,
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

  Widget _buildStaffTile(dynamic staff) {
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
          staff.displayName[0],
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        staff.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        staff.roleDisplay ?? staff.role?.localizedName(context.l10n) ?? '',
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
