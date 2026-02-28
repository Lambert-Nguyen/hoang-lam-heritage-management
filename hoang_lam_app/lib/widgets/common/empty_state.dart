import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A widget that displays an empty state with an icon, title, and message.
/// Used when there is no data to display in a list or grid.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? subtitle;
    return Center(
      child: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary),
            AppSpacing.gapVerticalMd,
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (displayMessage != null) ...[
              AppSpacing.gapVerticalSm,
              Text(
                displayMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[AppSpacing.gapVerticalLg, action!],
            if (action == null &&
                actionLabel != null &&
                onAction != null) ...[
              AppSpacing.gapVerticalLg,
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
