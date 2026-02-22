import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/housekeeping.dart';
import '../../providers/housekeeping_provider.dart';
import '../common/app_button.dart';

/// Bottom sheet for filtering housekeeping tasks
class TaskFilterSheet extends StatefulWidget {
  final HousekeepingTaskFilter? initialFilter;
  final Function(HousekeepingTaskFilter) onApply;

  const TaskFilterSheet({super.key, this.initialFilter, required this.onApply});

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late HousekeepingTaskStatus? _selectedStatus;
  late HousekeepingTaskType? _selectedType;
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialFilter?.status;
    _selectedType = widget.initialFilter?.taskType;
    _selectedDate = widget.initialFilter?.scheduledDate;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.filterTasks,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(context.l10n.clearFilters),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  Text(
                    context.l10n.status,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVerticalSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildFilterChip(
                        label: context.l10n.all,
                        isSelected: _selectedStatus == null,
                        onTap: () => setState(() => _selectedStatus = null),
                      ),
                      ...HousekeepingTaskStatus.values.map((status) {
                        return _buildFilterChip(
                          label: status.localizedName(context.l10n),
                          icon: status.icon,
                          color: status.color,
                          isSelected: _selectedStatus == status,
                          onTap: () => setState(() => _selectedStatus = status),
                        );
                      }),
                    ],
                  ),
                  AppSpacing.gapVerticalLg,

                  // Task type filter
                  Text(
                    context.l10n.taskTypeLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVerticalSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildFilterChip(
                        label: context.l10n.all,
                        isSelected: _selectedType == null,
                        onTap: () => setState(() => _selectedType = null),
                      ),
                      ...HousekeepingTaskType.values.map((type) {
                        return _buildFilterChip(
                          label: type.localizedName(context.l10n),
                          icon: type.icon,
                          color: type.color,
                          isSelected: _selectedType == type,
                          onTap: () => setState(() => _selectedType = type),
                        );
                      }),
                    ],
                  ),
                  AppSpacing.gapVerticalLg,

                  // Date filter
                  Text(
                    context.l10n.scheduledDate,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVerticalSm,
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _selectedDate != null
                                  ? AppColors.primary
                                  : AppColors.divider,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color:
                            _selectedDate != null
                                ? AppColors.primary.withValues(alpha: 0.05)
                                : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color:
                                _selectedDate != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                          ),
                          AppSpacing.gapHorizontalMd,
                          Text(
                            _selectedDate != null
                                ? dateFormat.format(_selectedDate!)
                                : context.l10n.selectDate,
                            style: TextStyle(
                              color:
                                  _selectedDate != null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed:
                                  () => setState(() => _selectedDate = null),
                              color: AppColors.textSecondary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalLg,

                  // Quick date filters
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildQuickDateChip(context.l10n.today, DateTime.now()),
                      _buildQuickDateChip(
                        context.l10n.tomorrow,
                        DateTime.now().add(const Duration(days: 1)),
                      ),
                      _buildQuickDateChip(
                        context.l10n.yesterday,
                        DateTime.now().subtract(const Duration(days: 1)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: context.l10n.applyBtn,
                  onPressed: _applyFilters,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (color ?? AppColors.primary).withValues(alpha: 0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? (color ?? AppColors.primary) : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color:
                    isSelected
                        ? (color ?? AppColors.primary)
                        : AppColors.textSecondary,
              ),
              AppSpacing.gapHorizontalXs,
            ],
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? (color ?? AppColors.primary)
                        : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTime date) {
    final isSelected =
        _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.secondary.withValues(alpha: 0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.secondary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi', 'VN'),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedType = null;
      _selectedDate = null;
    });
  }

  void _applyFilters() {
    widget.onApply(
      HousekeepingTaskFilter(
        status: _selectedStatus,
        taskType: _selectedType,
        scheduledDate: _selectedDate,
      ),
    );
    Navigator.pop(context);
  }
}
