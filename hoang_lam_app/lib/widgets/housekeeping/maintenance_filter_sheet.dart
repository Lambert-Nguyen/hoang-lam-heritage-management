import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/housekeeping.dart';
import '../../providers/housekeeping_provider.dart';
import '../common/app_button.dart';

/// Bottom sheet for filtering maintenance requests
class MaintenanceFilterSheet extends StatefulWidget {
  final MaintenanceRequestFilter? initialFilter;
  final Function(MaintenanceRequestFilter) onApply;

  const MaintenanceFilterSheet({
    super.key,
    this.initialFilter,
    required this.onApply,
  });

  @override
  State<MaintenanceFilterSheet> createState() => _MaintenanceFilterSheetState();
}

class _MaintenanceFilterSheetState extends State<MaintenanceFilterSheet> {
  late MaintenanceStatus? _selectedStatus;
  late MaintenancePriority? _selectedPriority;
  late MaintenanceCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialFilter?.status;
    _selectedPriority = widget.initialFilter?.priority;
    _selectedCategory = widget.initialFilter?.category;
  }

  @override
  Widget build(BuildContext context) {
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
                  context.l10n.filterMaintenanceRequests,
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
                      ...MaintenanceStatus.values.map((status) {
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

                  // Priority filter
                  Text(
                    context.l10n.priorityLevel,
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
                        isSelected: _selectedPriority == null,
                        onTap: () => setState(() => _selectedPriority = null),
                      ),
                      ...MaintenancePriority.values.map((priority) {
                        return _buildFilterChip(
                          label: priority.localizedName(context.l10n),
                          icon: priority.icon,
                          color: priority.color,
                          isSelected: _selectedPriority == priority,
                          onTap:
                              () =>
                                  setState(() => _selectedPriority = priority),
                        );
                      }),
                    ],
                  ),
                  AppSpacing.gapVerticalLg,

                  // Category filter
                  Text(
                    context.l10n.category,
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
                        isSelected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      ...MaintenanceCategory.values.map((category) {
                        return _buildFilterChip(
                          label: category.localizedName(context.l10n),
                          icon: category.icon,
                          color: category.color,
                          isSelected: _selectedCategory == category,
                          onTap:
                              () =>
                                  setState(() => _selectedCategory = category),
                        );
                      }),
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
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedCategory = null;
    });
  }

  void _applyFilters() {
    widget.onApply(
      MaintenanceRequestFilter(
        status: _selectedStatus,
        priority: _selectedPriority,
        category: _selectedCategory,
      ),
    );
    Navigator.pop(context);
  }
}
