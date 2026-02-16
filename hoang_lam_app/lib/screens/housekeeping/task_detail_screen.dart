import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/housekeeping.dart';
import '../../providers/housekeeping_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/housekeeping/assign_task_dialog.dart';
import '../../widgets/housekeeping/complete_task_dialog.dart';

/// Screen showing detailed information about a housekeeping task
class TaskDetailScreen extends ConsumerStatefulWidget {
  final HousekeepingTask task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late HousekeepingTask _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.room} ${_task.roomNumber ?? _task.room}'),
        actions: [
          if (_task.status.canVerify)
            IconButton(
              icon: const Icon(Icons.verified),
              onPressed: _verifyTask,
              tooltip: l10n.verify,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _deleteTask();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            _buildStatusHeader(),
            AppSpacing.gapVerticalLg,

            // Task info card
            _buildInfoCard(dateFormat),
            AppSpacing.gapVerticalLg,

            // Assignment info
            _buildAssignmentCard(),
            AppSpacing.gapVerticalLg,

            // Notes section
            if (_task.notes != null && _task.notes!.isNotEmpty) ...[
              _buildNotesSection(),
              AppSpacing.gapVerticalLg,
            ],

            // Timeline
            _buildTimelineSection(dateFormat, timeFormat),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _task.status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _task.status.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _task.status.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _task.status.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _task.status.localizedName(context.l10n),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _task.status.color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                AppSpacing.gapVerticalXs,
                Text(
                  _task.taskType.localizedName(context.l10n),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            _task.taskType.icon,
            color: _task.taskType.color,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DateFormat dateFormat) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.taskInfo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            Icons.meeting_room,
            l10n.room,
            _task.roomNumber ?? '${l10n.room} ${_task.room}',
          ),
          _buildInfoRow(
            Icons.cleaning_services,
            l10n.taskType,
            _task.taskType.localizedName(context.l10n),
          ),
          _buildInfoRow(
            Icons.calendar_today,
            l10n.scheduledDate,
            dateFormat.format(_task.scheduledDate),
          ),
          if (_task.booking != null)
            _buildInfoRow(
              Icons.book_online,
              l10n.bookingCode,
              '#${_task.booking}',
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard() {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.assign,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_task.status.canAssign)
                TextButton.icon(
                  onPressed: _assignTask,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: Text(l10n.assign),
                ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          if (_task.assignedTo != null) ...[
            _buildInfoRow(
              Icons.person,
              l10n.assignee,
              _task.assignedToName ?? 'ID: ${_task.assignedTo}',
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    l10n.notAssigned,
                    style: TextStyle(color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ],
          if (_task.createdBy != null) ...[
            AppSpacing.gapVerticalMd,
            _buildInfoRow(
              Icons.person_outline,
              l10n.creator,
              _task.createdByName ?? 'ID: ${_task.createdBy}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.notes,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          Text(
            _task.notes!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(DateFormat dateFormat, DateFormat timeFormat) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.historyLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          if (_task.createdAt != null)
            _buildTimelineItem(
              l10n.createdAt,
              '${dateFormat.format(_task.createdAt!)} ${timeFormat.format(_task.createdAt!)}',
              Icons.add_circle_outline,
              AppColors.primary,
            ),
          if (_task.completedAt != null)
            _buildTimelineItem(
              l10n.completedAt,
              '${dateFormat.format(_task.completedAt!)} ${timeFormat.format(_task.completedAt!)}',
              Icons.check_circle_outline,
              AppColors.success,
            ),
          if (_task.updatedAt != null && _task.updatedAt != _task.createdAt)
            _buildTimelineItem(
              l10n.updatedAt,
              '${dateFormat.format(_task.updatedAt!)} ${timeFormat.format(_task.updatedAt!)}',
              Icons.update,
              AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          AppSpacing.gapHorizontalSm,
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (_task.status.canAssign && _task.assignedTo == null)
              Expanded(
                child: AppButton(
                  label: l10n.assign,
                  onPressed: _assignTask,
                  isOutlined: true,
                  icon: Icons.person_add,
                ),
              ),
            if (_task.status.canAssign && _task.assignedTo == null)
              AppSpacing.gapHorizontalMd,
            if (_task.status.canComplete)
              Expanded(
                child: AppButton(
                  label: l10n.completed,
                  onPressed: _completeTask,
                  icon: Icons.check,
                ),
              ),
            if (_task.status.canVerify)
              Expanded(
                child: AppButton(
                  label: l10n.verify,
                  onPressed: _verifyTask,
                  icon: Icons.verified,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignTask() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = await showDialog<int>(
      context: context,
      builder: (context) => AssignTaskDialog(task: _task),
    );

    if (userId != null && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedTask = await notifier.assignTask(_task.id, userId);
      if (updatedTask != null && mounted) {
        setState(() {
          _task = updatedTask;
        });
        ref.invalidate(housekeepingTasksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskAssigned)),
        );
      }
    }
  }

  Future<void> _completeTask() async {
    final l10n = AppLocalizations.of(context)!;
    final notes = await showDialog<String?>(
      context: context,
      builder: (context) => CompleteTaskDialog(task: _task),
    );

    if (notes != null && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedTask =
          await notifier.completeTask(_task.id, notes: notes.isNotEmpty ? notes : null);
      if (updatedTask != null && mounted) {
        setState(() {
          _task = updatedTask;
        });
        ref.invalidate(housekeepingTasksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskCompleted)),
        );
      }
    }
  }

  Future<void> _verifyTask() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.verifyTask),
        content: Text(l10n.verifyTaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.verify),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedTask = await notifier.verifyTask(_task.id);
      if (updatedTask != null && mounted) {
        setState(() {
          _task = updatedTask;
        });
        ref.invalidate(housekeepingTasksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskVerified)),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text(l10n.deleteTaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final success = await notifier.deleteTask(_task.id);
      if (success && mounted) {
        ref.invalidate(housekeepingTasksProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskDeleted)),
        );
      }
    }
  }
}
