import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/housekeeping.dart';

/// A card widget displaying a maintenance request summary
class MaintenanceCard extends StatelessWidget {
  final MaintenanceRequest request;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final VoidCallback? onComplete;

  const MaintenanceCard({
    super.key,
    required this.request,
    this.onTap,
    this.onAssign,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM');

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: request.priority.color.withValues(alpha: 0.3),
          width: request.priority == MaintenancePriority.urgent ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Room number
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'P.${request.roomNumber ?? request.room}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,

                  // Priority badge
                  _PriorityBadge(priority: request.priority),

                  const Spacer(),

                  // Status badge
                  _StatusBadge(status: request.status),
                ],
              ),

              AppSpacing.gapVerticalSm,

              // Title
              Text(
                request.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              AppSpacing.gapVerticalXs,

              // Category and date row
              Row(
                children: [
                  // Category
                  Icon(
                    request.category.icon,
                    size: 14,
                    color: request.category.color,
                  ),
                  AppSpacing.gapHorizontalXs,
                  Text(
                    request.category.localizedName(context.l10n),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: request.category.color,
                        ),
                  ),
                  AppSpacing.gapHorizontalMd,

                  // Date
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapHorizontalXs,
                  Text(
                    request.createdAt != null
                        ? dateFormat.format(request.createdAt!)
                        : 'N/A',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),

                  const Spacer(),

                  // Assigned to
                  if (request.assignedTo != null) ...[
                    Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.gapHorizontalXs,
                    Flexible(
                      child: Text(
                        request.assignedToName ?? 'ID: ${request.assignedTo}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.unassigned,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ],
              ),

              // Description preview
              if (request.description.isNotEmpty) ...[
                AppSpacing.gapVerticalSm,
                Text(
                  request.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Quick actions
              if (request.status.canAssign ||
                  request.status.canComplete) ...[
                AppSpacing.gapVerticalSm,
                const Divider(height: 1),
                AppSpacing.gapVerticalSm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (request.status.canAssign &&
                        request.assignedTo == null &&
                        onAssign != null)
                      TextButton.icon(
                        onPressed: onAssign,
                        icon: const Icon(Icons.person_add, size: 16),
                        label: Text(context.l10n.assign),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                      ),
                    if (request.status.canComplete && onComplete != null)
                      TextButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(context.l10n.completeBtn),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MaintenanceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 12,
            color: status.color,
          ),
          AppSpacing.gapHorizontalXs,
          Text(
            status.localizedName(context.l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final MaintenancePriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priority.icon,
            size: 12,
            color: priority.color,
          ),
          AppSpacing.gapHorizontalXs,
          Text(
            priority.localizedName(context.l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: priority.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
