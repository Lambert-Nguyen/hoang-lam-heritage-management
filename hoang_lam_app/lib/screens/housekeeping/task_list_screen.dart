import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/housekeeping.dart';
import '../../providers/housekeeping_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/housekeeping/task_card.dart';
import '../../widgets/housekeeping/task_filter_sheet.dart';

/// Screen showing list of housekeeping tasks
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HousekeepingTaskFilter _filter = const HousekeepingTaskFilter();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.housekeepingTasks),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: l10n.filter,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _tabLabel(l10n.today, ref.watch(todayTasksProvider))),
            Tab(text: _tabLabel(l10n.all, ref.watch(filteredTasksProvider(_filter)))),
            Tab(text: _tabLabel(l10n.myTasks, ref.watch(myTasksProvider))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTodayTab(), _buildAllTasksTab(), _buildMyTasksTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        tooltip: l10n.createNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTab() {
    final l10n = AppLocalizations.of(context)!;
    final todayTasksAsync = ref.watch(todayTasksProvider);

    return todayTasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return EmptyState(
            icon: Icons.check_circle_outline,
            title: l10n.noTasks,
            message: l10n.noTasksScheduledToday,
          );
        }
        return _buildTaskList(tasks, showPriorityHint: true);
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildAllTasksTab() {
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(filteredTasksProvider(_filter));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return EmptyState(
            icon: Icons.cleaning_services,
            title: l10n.noTasks,
            message: l10n.noTasksCreated,
          );
        }
        return _buildTaskList(tasks);
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildMyTasksTab() {
    final l10n = AppLocalizations.of(context)!;
    final myTasksAsync = ref.watch(myTasksProvider);

    return myTasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return EmptyState(
            icon: Icons.person_outline,
            title: l10n.noTasks,
            message: l10n.noTasksAssigned,
          );
        }
        return _buildTaskList(tasks);
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  /// Sort tasks by priority: checkout cleans first (rooms with upcoming
  /// check-ins need to be cleaned before new guests arrive), then by
  /// scheduled date (earliest first), then by creation date (oldest first).
  void _sortByPriority(List<HousekeepingTask> tasks) {
    tasks.sort((a, b) {
      // 1. Task type priority: checkout_clean > stay_clean > others
      final typePriority = _taskTypePriority(a.taskType)
          .compareTo(_taskTypePriority(b.taskType));
      if (typePriority != 0) return typePriority;

      // 2. Scheduled date: earliest first
      final dateCompare = a.scheduledDate.compareTo(b.scheduledDate);
      if (dateCompare != 0) return dateCompare;

      // 3. Created date: oldest first (waiting longest = most urgent)
      final aCreated = a.createdAt;
      final bCreated = b.createdAt;
      if (aCreated != null && bCreated != null) {
        return aCreated.compareTo(bCreated);
      }
      return 0;
    });
  }

  /// Lower number = higher priority.
  int _taskTypePriority(HousekeepingTaskType type) {
    switch (type) {
      case HousekeepingTaskType.checkoutClean:
        return 0; // Highest: room has upcoming check-in
      case HousekeepingTaskType.stayClean:
        return 1; // Guest currently staying
      case HousekeepingTaskType.inspection:
        return 2;
      case HousekeepingTaskType.deepClean:
        return 3;
      case HousekeepingTaskType.maintenance:
        return 4;
    }
  }

  Widget _buildTaskList(
    List<HousekeepingTask> tasks, {
    bool showPriorityHint = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // Group tasks by status
    final pendingTasks = tasks
        .where((t) => t.status == HousekeepingTaskStatus.pending)
        .toList();
    final inProgressTasks = tasks
        .where((t) => t.status == HousekeepingTaskStatus.inProgress)
        .toList();
    final completedTasks = tasks
        .where(
          (t) =>
              t.status == HousekeepingTaskStatus.completed ||
              t.status == HousekeepingTaskStatus.verified,
        )
        .toList();

    // Sort each group by priority when requested (Today tab)
    if (showPriorityHint) {
      _sortByPriority(pendingTasks);
      _sortByPriority(inProgressTasks);
    }

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // Priority hint banner for the Today tab
          if (showPriorityHint) _buildPriorityHint(l10n),
          if (pendingTasks.isNotEmpty) ...[
            _buildSectionHeader(l10n.pending, pendingTasks.length),
            ...pendingTasks.map(
              (task) => TaskCard(task: task, onTap: () => _viewTask(task)),
            ),
          ],
          if (inProgressTasks.isNotEmpty) ...[
            if (pendingTasks.isNotEmpty) AppSpacing.gapVerticalLg,
            _buildSectionHeader(l10n.inProgress, inProgressTasks.length),
            ...inProgressTasks.map(
              (task) => TaskCard(task: task, onTap: () => _viewTask(task)),
            ),
          ],
          if (completedTasks.isNotEmpty) ...[
            if (pendingTasks.isNotEmpty || inProgressTasks.isNotEmpty)
              AppSpacing.gapVerticalLg,
            _buildSectionHeader(l10n.completed, completedTasks.length),
            ...completedTasks.map(
              (task) => TaskCard(task: task, onTap: () => _viewTask(task)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityHint(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.sort, size: 14, color: AppColors.textSecondary),
          AppSpacing.gapHorizontalXs,
          Text(
            l10n.sortedByPriority,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapHorizontalSm,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            AppSpacing.gapVerticalMd,
            Text(
              l10n.errorOccurred,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.gapVerticalLg,
            ElevatedButton(onPressed: _refreshTasks, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }

  String _tabLabel(String label, AsyncValue<List<HousekeepingTask>> async) {
    final count = async.valueOrNull?.length;
    return count != null ? '$label ($count)' : label;
  }

  Future<void> _refreshTasks() async {
    ref.invalidate(todayTasksProvider);
    ref.invalidate(myTasksProvider);
    ref.invalidate(filteredTasksProvider(_filter));
  }

  Future<void> _showFilterSheet() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskFilterSheet(
        initialFilter: _filter,
        onApply: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _viewTask(HousekeepingTask task) {
    context.push('${AppRoutes.housekeepingTaskDetail}/${task.id}', extra: task);
  }

  void _createTask() {
    context.push(AppRoutes.housekeepingNewTask);
  }
}
