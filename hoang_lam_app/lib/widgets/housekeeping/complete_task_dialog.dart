import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
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
  bool _isChecklistInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isChecklistInitialized) {
      _isChecklistInitialized = true;
      _initializeChecklist();
    }
  }

  void _initializeChecklist() {
    final l10n = AppLocalizations.of(context)!;
    // Initialize checklist based on task type
    switch (widget.task.taskType) {
      case HousekeepingTaskType.checkoutClean:
        _checklist.addAll([
          _ChecklistItem(label: l10n.changeBedSheets),
          _ChecklistItem(label: l10n.cleanBathroom),
          _ChecklistItem(label: l10n.vacuum),
          _ChecklistItem(label: l10n.mopFloor),
          _ChecklistItem(label: l10n.restockSupplies),
          _ChecklistItem(label: l10n.checkMinibar),
        ]);
        break;
      case HousekeepingTaskType.stayClean:
        _checklist.addAll([
          _ChecklistItem(label: l10n.generalCleaning),
          _ChecklistItem(label: l10n.changeTowels),
          _ChecklistItem(label: l10n.emptyTrash),
          _ChecklistItem(label: l10n.restockWater),
        ]);
        break;
      case HousekeepingTaskType.deepClean:
        _checklist.addAll([
          _ChecklistItem(label: l10n.deepCleanBathroom),
          _ChecklistItem(label: l10n.washCurtains),
          _ChecklistItem(label: l10n.cleanAC),
          _ChecklistItem(label: l10n.cleanGlass),
          _ChecklistItem(label: l10n.cleanFridge),
          _ChecklistItem(label: l10n.checkFurniture),
        ]);
        break;
      case HousekeepingTaskType.inspection:
        _checklist.addAll([
          _ChecklistItem(label: l10n.checkCleanliness),
          _ChecklistItem(label: l10n.checkEquipment),
          _ChecklistItem(label: l10n.checkSupplies),
          _ChecklistItem(label: l10n.checkSafety),
        ]);
        break;
      case HousekeepingTaskType.maintenance:
        _checklist.addAll([
          _ChecklistItem(label: l10n.checkForIssues),
          _ChecklistItem(label: l10n.performRepair),
          _ChecklistItem(label: l10n.reinspect),
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
    final l10n = AppLocalizations.of(context)!;
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
                          l10n.completeTaskTitle,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '${l10n.roomLabel} ${widget.task.roomNumber ?? widget.task.room}',
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
                      l10n.checklistLabel,
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
                      l10n.notesOptional,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    AppSpacing.gapVerticalSm,
                    AppTextField(
                      controller: _notesController,
                      hint: l10n.enterTaskNotes,
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
                              l10n.completeAllItemsWarning,
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
                          label: l10n.cancel,
                          onPressed: () => Navigator.pop(context),
                          isOutlined: true,
                        ),
                      ),
                      AppSpacing.gapHorizontalMd,
                      Expanded(
                        child: AppButton(
                          label: l10n.completeBtn,
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
