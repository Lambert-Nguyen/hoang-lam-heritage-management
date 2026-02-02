import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/housekeeping.dart';
import '../../providers/housekeeping_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/housekeeping/task_card.dart';
import '../../widgets/housekeeping/task_filter_sheet.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc Housekeeping'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Lọc',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Tất cả'),
            Tab(text: 'Của tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildAllTasksTab(),
          _buildMyTasksTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        tooltip: 'Tạo công việc mới',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTab() {
    final todayTasksAsync = ref.watch(todayTasksProvider);

    return todayTasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Không có công việc',
            message: 'Không có công việc nào được lên lịch cho hôm nay',
          );
        }
        return _buildTaskList(tasks);
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildAllTasksTab() {
    final tasksAsync = ref.watch(filteredTasksProvider(_filter));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const EmptyState(
            icon: Icons.cleaning_services,
            title: 'Không có công việc',
            message: 'Chưa có công việc nào được tạo',
          );
        }
        return _buildTaskList(tasks);
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildMyTasksTab() {
    final myTasksAsync = ref.watch(myTasksProvider);

    return myTasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const EmptyState(
            icon: Icons.person_outline,
            title: 'Không có công việc',
            message: 'Bạn chưa được phân công công việc nào',
          );
        }
        return _buildTaskList(tasks);
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTaskList(List<HousekeepingTask> tasks) {
    // Group tasks by status
    final pendingTasks =
        tasks.where((t) => t.status == HousekeepingTaskStatus.pending).toList();
    final inProgressTasks =
        tasks.where((t) => t.status == HousekeepingTaskStatus.inProgress).toList();
    final completedTasks = tasks
        .where((t) =>
            t.status == HousekeepingTaskStatus.completed ||
            t.status == HousekeepingTaskStatus.verified)
        .toList();

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          if (pendingTasks.isNotEmpty) ...[
            _buildSectionHeader('Chờ xử lý', pendingTasks.length),
            ...pendingTasks.map((task) => TaskCard(
                  task: task,
                  onTap: () => _viewTask(task),
                )),
          ],
          if (inProgressTasks.isNotEmpty) ...[
            if (pendingTasks.isNotEmpty) AppSpacing.gapVerticalLg,
            _buildSectionHeader('Đang làm', inProgressTasks.length),
            ...inProgressTasks.map((task) => TaskCard(
                  task: task,
                  onTap: () => _viewTask(task),
                )),
          ],
          if (completedTasks.isNotEmpty) ...[
            if (pendingTasks.isNotEmpty || inProgressTasks.isNotEmpty)
              AppSpacing.gapVerticalLg,
            _buildSectionHeader('Hoàn thành', completedTasks.length),
            ...completedTasks.map((task) => TaskCard(
                  task: task,
                  onTap: () => _viewTask(task),
                )),
          ],
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
    return Center(
      child: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            AppSpacing.gapVerticalMd,
            Text(
              'Đã xảy ra lỗi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            AppSpacing.gapVerticalLg,
            ElevatedButton(
              onPressed: _refreshTasks,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshTasks() async {
    ref.invalidate(todayTasksProvider);
    ref.invalidate(myTasksProvider);
    ref.invalidate(filteredTasksProvider(_filter));
  }

  void _showFilterSheet() async {
    final newFilter = await showModalBottomSheet<HousekeepingTaskFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskFilterSheet(currentFilter: _filter),
    );

    if (newFilter != null) {
      setState(() {
        _filter = newFilter;
      });
    }
  }

  void _viewTask(HousekeepingTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  void _createTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskFormScreen(),
      ),
    );
  }
}
