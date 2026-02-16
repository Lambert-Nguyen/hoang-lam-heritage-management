import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/room_inspection.dart';
import '../../providers/room_inspection_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen for listing all room inspections
class RoomInspectionListScreen extends ConsumerStatefulWidget {
  const RoomInspectionListScreen({super.key});

  @override
  ConsumerState<RoomInspectionListScreen> createState() => _RoomInspectionListScreenState();
}

class _RoomInspectionListScreenState extends ConsumerState<RoomInspectionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  InspectionType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inspectionsAsync = ref.watch(roomInspectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roomInspection),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: l10n.statistics,
            onPressed: _showStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: l10n.inspectionTemplate,
            onPressed: () => context.push('/inspection-templates'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.pending),
            Tab(text: l10n.completed),
            Tab(text: l10n.requiresAction),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: inspectionsAsync.when(
              data: (inspections) => TabBarView(
                controller: _tabController,
                children: [
                  _buildInspectionList(inspections, null),
                  _buildInspectionList(inspections, InspectionStatus.pending),
                  _buildInspectionList(inspections, InspectionStatus.completed),
                  _buildInspectionList(inspections, InspectionStatus.requiresAction),
                ],
              ),
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorDisplay(
                message: '${l10n.error}: $e',
                onRetry: () => ref.invalidate(roomInspectionsProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/room-inspections/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.createInspection),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: AppSpacing.paddingHorizontal,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.search,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _typeFilter != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _typeFilter = null),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: InspectionType.values.map((type) {
                final isSelected = _typeFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type.localizedName(context.l10n)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _typeFilter = selected ? type : null);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildInspectionList(List<RoomInspection> inspections, InspectionStatus? status) {
    var filtered = inspections.where((i) {
      if (status != null && i.status != status) {
        return false;
      }
      if (_typeFilter != null && i.inspectionType != _typeFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !i.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(roomInspectionsProvider),
      child: ListView.builder(
        padding: AppSpacing.paddingAll,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final inspection = filtered[index];
          return _InspectionCard(
            inspection: inspection,
            onTap: () => context.push('/room-inspections/${inspection.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(InspectionStatus? status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(
            status == InspectionStatus.pending
                ? AppLocalizations.of(context)!.noPendingInspections
                : status == InspectionStatus.completed
                    ? AppLocalizations.of(context)!.noCompletedInspections
                    : status == InspectionStatus.requiresAction
                        ? AppLocalizations.of(context)!.noActionRequiredInspections
                        : AppLocalizations.of(context)!.noInspectionsYet,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, _) {
              final statsAsync = ref.watch(inspectionStatisticsProvider);
              return Container(
                padding: AppSpacing.paddingAll,
                child: statsAsync.when(
                  data: (stats) => ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(context.l10n.inspectionStatistics, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.lg),
                      _StatCard(
                        title: context.l10n.totalInspections,
                        value: stats.totalInspections.toString(),
                        icon: Icons.checklist,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: context.l10n.completed,
                        value: stats.completedInspections.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: context.l10n.pending,
                        value: stats.pendingInspections.toString(),
                        icon: Icons.schedule,
                        color: Colors.grey,
                      ),
                      _StatCard(
                        title: context.l10n.requiresAction,
                        value: stats.requiresAction.toString(),
                        icon: Icons.warning,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        child: Padding(
                          padding: AppSpacing.paddingCard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.averageScore, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${stats.averageScore.toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: _getScoreColor(stats.averageScore),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: stats.averageScore / 100,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation(_getScoreColor(stats.averageScore)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        child: Padding(
                          padding: AppSpacing.paddingCard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.issuesDetected, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          stats.totalIssues.toString(),
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(context.l10n.totalIssues),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          stats.criticalIssues.toString(),
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                        ),
                                        Text(context.l10n.criticalLabel),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => ErrorDisplay(message: '${context.l10n.error}: $e'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) {
      return Colors.green;
    }
    if (score >= 70) {
      return Colors.orange;
    }
    return Colors.red;
  }
}

class _InspectionCard extends StatelessWidget {
  final RoomInspection inspection;
  final VoidCallback onTap;

  const _InspectionCard({required this.inspection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: inspection.inspectionType.icon == Icons.logout
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    inspection.inspectionType.icon,
                    color: inspection.inspectionType == InspectionType.checkout
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.roomWithNumber.replaceAll('{number}', inspection.roomNumber),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        inspection.inspectionType.localizedName(context.l10n),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(inspection.scheduledDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                if (inspection.inspectorName != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    inspection.inspectorName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
            if (inspection.status == InspectionStatus.completed ||
                inspection.status == InspectionStatus.requiresAction) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.scoreValueDisplay.replaceAll('{value}', inspection.score.toStringAsFixed(0)),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getScoreColor(inspection.score),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (inspection.issuesFound > 0) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${inspection.issuesFound} ${AppLocalizations.of(context)!.issuesCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
                    ),
                  ],
                  if (inspection.criticalIssues > 0) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.error, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${inspection.criticalIssues} ${AppLocalizations.of(context)!.criticalIssuesLabel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: inspection.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(inspection.status.icon, size: 14, color: inspection.status.color),
          const SizedBox(width: 4),
          Text(
            inspection.status.localizedName(context.l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: inspection.status.color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 90) {
      return Colors.green;
    }
    if (score >= 70) {
      return Colors.orange;
    }
    return Colors.red;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
