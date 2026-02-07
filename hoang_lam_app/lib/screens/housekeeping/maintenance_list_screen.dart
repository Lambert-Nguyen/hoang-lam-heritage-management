import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/housekeeping.dart';
import '../../providers/housekeeping_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/housekeeping/maintenance_card.dart';
import '../../widgets/housekeeping/maintenance_filter_sheet.dart';
import 'maintenance_detail_screen.dart';
import 'maintenance_form_screen.dart';

/// Screen displaying a list of maintenance requests
class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MaintenanceRequestFilter _filter = const MaintenanceRequestFilter();

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
        title: Text(l10n.maintenance),
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
            Tab(text: l10n.urgent),
            Tab(text: l10n.all),
            Tab(text: l10n.myTasks),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUrgentTab(),
          _buildAllTab(),
          _buildMyRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.createRequest),
      ),
    );
  }

  Widget _buildUrgentTab() {
    final l10n = AppLocalizations.of(context)!;
    final urgentAsync = ref.watch(urgentRequestsProvider);

    return urgentAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.check_circle_outline,
            title: l10n.noUrgentRequests,
            message: l10n.noUrgentMaintenanceRequests,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(urgentRequestsProvider);
          },
          child: _buildRequestList(requests),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error, () {
        ref.invalidate(urgentRequestsProvider);
      }),
    );
  }

  Widget _buildAllTab() {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(filteredMaintenanceRequestsProvider(_filter));

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.build_outlined,
            title: l10n.noMaintenanceRequests,
            message: l10n.noMaintenanceRequestsCreated,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(filteredMaintenanceRequestsProvider(_filter));
          },
          child: _buildRequestList(requests),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error, () {
        ref.invalidate(filteredMaintenanceRequestsProvider(_filter));
      }),
    );
  }

  Widget _buildMyRequestsTab() {
    final l10n = AppLocalizations.of(context)!;
    final myRequestsAsync = ref.watch(myMaintenanceRequestsProvider);

    return myRequestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.person_outline,
            title: l10n.noYourRequests,
            message: l10n.noAssignedMaintenanceRequests,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myMaintenanceRequestsProvider);
          },
          child: _buildRequestList(requests),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => _buildErrorState(error, () {
        ref.invalidate(myMaintenanceRequestsProvider);
      }),
    );
  }

  Widget _buildRequestList(List<MaintenanceRequest> requests) {
    final l10n = AppLocalizations.of(context)!;
    // Group requests by status
    final pending = requests.where((r) => r.status == MaintenanceStatus.pending).toList();
    final assigned = requests.where((r) => r.status == MaintenanceStatus.assigned).toList();
    final inProgress = requests.where((r) => r.status == MaintenanceStatus.inProgress).toList();
    final onHold = requests.where((r) => r.status == MaintenanceStatus.onHold).toList();
    final completed = requests.where((r) => 
      r.status == MaintenanceStatus.completed || 
      r.status == MaintenanceStatus.cancelled
    ).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (pending.isNotEmpty) ...[
          _buildSectionHeader(l10n.pending, pending.length, MaintenanceStatus.pending.color),
          ...pending.map((r) => _buildRequestCard(r)),
        ],
        if (assigned.isNotEmpty) ...[
          _buildSectionHeader(l10n.assigned, assigned.length, MaintenanceStatus.assigned.color),
          ...assigned.map((r) => _buildRequestCard(r)),
        ],
        if (inProgress.isNotEmpty) ...[
          _buildSectionHeader(l10n.inProgress, inProgress.length, MaintenanceStatus.inProgress.color),
          ...inProgress.map((r) => _buildRequestCard(r)),
        ],
        if (onHold.isNotEmpty) ...[
          _buildSectionHeader(l10n.onHold, onHold.length, MaintenanceStatus.onHold.color),
          ...onHold.map((r) => _buildRequestCard(r)),
        ],
        if (completed.isNotEmpty) ...[
          _buildSectionHeader(l10n.completedCancelled, completed.length, MaintenanceStatus.completed.color),
          ...completed.map((r) => _buildRequestCard(r)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppSpacing.gapHorizontalSm,
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          AppSpacing.gapHorizontalXs,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(MaintenanceRequest request) {
    return MaintenanceCard(
      request: request,
      onTap: () => _navigateToDetail(context, request),
      onAssign: request.status.canAssign
          ? () => _assignRequest(request)
          : null,
      onComplete: request.status.canComplete
          ? () => _completeRequest(request)
          : null,
    );
  }

  Widget _buildErrorState(Object error, VoidCallback onRetry) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              l10n.errorOccurred,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalLg,
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MaintenanceFilterSheet(
        initialFilter: _filter,
        onApply: (filter) {
          setState(() {
            _filter = filter;
          });
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, MaintenanceRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceDetailScreen(request: request),
      ),
    );
  }

  void _navigateToForm(BuildContext context, [MaintenanceRequest? request]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceFormScreen(request: request),
      ),
    );
  }

  Future<void> _assignRequest(MaintenanceRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    // Show assign dialog - similar to task assignment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.assignmentInDevelopment)),
    );
  }

  Future<void> _completeRequest(MaintenanceRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.completeRequest),
        content: Text(l10n.completeRequestConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.completed),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final result = await notifier.completeMaintenanceRequest(request.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.maintenanceRequestCompleted)),
        );
      }
    }
  }
}
