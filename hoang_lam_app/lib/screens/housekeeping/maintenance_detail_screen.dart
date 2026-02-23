import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/housekeeping.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/housekeeping_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

/// Screen showing detailed information about a maintenance request
class MaintenanceDetailScreen extends ConsumerStatefulWidget {
  final MaintenanceRequest request;

  const MaintenanceDetailScreen({super.key, required this.request});

  @override
  ConsumerState<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState
    extends ConsumerState<MaintenanceDetailScreen> {
  late MaintenanceRequest _request;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.room} ${_request.roomNumber ?? _request.room}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'hold':
                  _holdRequest();
                  break;
                case 'resume':
                  _resumeRequest();
                  break;
                case 'cancel':
                  _cancelRequest();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (_request.status.canHold)
                PopupMenuItem(
                  value: 'hold',
                  child: Row(
                    children: [
                      const Icon(Icons.pause),
                      const SizedBox(width: 8),
                      Text(l10n.hold),
                    ],
                  ),
                ),
              if (_request.status == MaintenanceStatus.onHold)
                PopupMenuItem(
                  value: 'resume',
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(l10n.resume),
                    ],
                  ),
                ),
              if (_request.status.canCancel)
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        l10n.cancel,
                        style: const TextStyle(color: AppColors.error),
                      ),
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
            // Status and Priority header
            _buildStatusHeader(),
            AppSpacing.gapVerticalLg,

            // Request info card
            _buildInfoCard(),
            AppSpacing.gapVerticalLg,

            // Assignment info
            _buildAssignmentCard(),
            AppSpacing.gapVerticalLg,

            // Description section
            if (_request.description.isNotEmpty) ...[
              _buildDescriptionSection(),
              AppSpacing.gapVerticalLg,
            ],

            // Resolution notes
            if (_request.resolutionNotes != null &&
                _request.resolutionNotes!.isNotEmpty) ...[
              _buildResolutionSection(),
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
        color: _request.status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _request.status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _request.status.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_request.status.icon, color: Colors.white, size: 32),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _request.status.localizedName(context.l10n),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _request.status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapVerticalXs,
                Row(
                  children: [
                    _buildPriorityBadge(),
                    AppSpacing.gapHorizontalSm,
                    _buildCategoryBadge(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _request.priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _request.priority.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _request.priority.icon,
            size: 14,
            color: _request.priority.color,
          ),
          AppSpacing.gapHorizontalXs,
          Text(
            _request.priority.localizedName(context.l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _request.priority.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _request.category.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _request.category.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _request.category.icon,
            size: 14,
            color: _request.category.color,
          ),
          AppSpacing.gapHorizontalXs,
          Text(
            _request.category.localizedName(context.l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _request.category.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.requestInfo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            Icons.meeting_room,
            l10n.room,
            _request.roomNumber ?? '${l10n.room} ${_request.room}',
          ),
          _buildInfoRow(Icons.title, l10n.title, _request.title),
          _buildInfoRow(
            Icons.category,
            l10n.category,
            _request.category.localizedName(context.l10n),
          ),
          _buildInfoRow(
            Icons.priority_high,
            l10n.priorityLevel,
            _request.priority.localizedName(context.l10n),
          ),
          if (_request.estimatedCost != null)
            _buildInfoRow(
              Icons.attach_money,
              l10n.estimatedCostOptional,
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: '₫',
              ).format(_request.estimatedCost),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_request.status.canAssign)
                TextButton.icon(
                  onPressed: _assignRequest,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: Text(l10n.assign),
                ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          if (_request.assignedTo != null) ...[
            _buildInfoRow(
              Icons.person,
              l10n.assignee,
              _request.assignedToName ?? 'ID: ${_request.assignedTo}',
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
          if (_request.reportedBy != null) ...[
            AppSpacing.gapVerticalMd,
            _buildInfoRow(
              Icons.person_outline,
              l10n.reporter,
              _request.reportedByName ?? 'ID: ${_request.reportedBy}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.description,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapVerticalMd,
          Text(
            _request.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionSection() {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              AppSpacing.gapHorizontalSm,
              Text(
                l10n.resolutionResult,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Text(
            _request.resolutionNotes!,
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapVerticalMd,
          if (_request.createdAt != null)
            _buildTimelineItem(
              l10n.createdAt,
              '${dateFormat.format(_request.createdAt!)} ${timeFormat.format(_request.createdAt!)}',
              Icons.add_circle_outline,
              AppColors.primary,
            ),
          if (_request.completedAt != null)
            _buildTimelineItem(
              l10n.completedAt,
              '${dateFormat.format(_request.completedAt!)} ${timeFormat.format(_request.completedAt!)}',
              Icons.check_circle_outline,
              AppColors.success,
            ),
          if (_request.updatedAt != null &&
              _request.updatedAt != _request.createdAt)
            _buildTimelineItem(
              l10n.updatedAt,
              '${dateFormat.format(_request.updatedAt!)} ${timeFormat.format(_request.updatedAt!)}',
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
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
                Text(time, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context)!;
    if (!_request.status.canAssign && !_request.status.canComplete) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (_request.status.canAssign && _request.assignedTo == null)
              Expanded(
                child: AppButton(
                  label: l10n.assign,
                  onPressed: _assignRequest,
                  isOutlined: true,
                  icon: Icons.person_add,
                ),
              ),
            if (_request.status.canAssign && _request.assignedTo == null)
              AppSpacing.gapHorizontalMd,
            if (_request.status.canComplete)
              Expanded(
                child: AppButton(
                  label: l10n.completed,
                  onPressed: _completeRequest,
                  icon: Icons.check,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = await showDialog<int>(
      context: context,
      builder: (context) => _AssignDialog(request: _request),
    );

    if (userId != null && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final result = await notifier.assignMaintenanceRequest(
        _request.id,
        userId,
      );
      if (result != null && mounted) {
        setState(() {
          _request = result;
        });
        ref.invalidate(maintenanceRequestsProvider);
        ref.invalidate(maintenanceRequestByIdProvider(_request.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.taskAssigned)));
      }
    }
  }

  Future<void> _completeRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final notes = await showDialog<String?>(
      context: context,
      builder: (context) => _CompletionDialog(request: _request),
    );

    if (notes != null && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedRequest = await notifier.completeMaintenanceRequest(
        _request.id,
        resolutionNotes: notes.isNotEmpty ? notes : null,
      );
      if (updatedRequest != null && mounted) {
        setState(() {
          _request = updatedRequest;
        });
        ref.invalidate(maintenanceRequestsProvider);
        ref.invalidate(maintenanceRequestByIdProvider(_request.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.maintenanceRequestCompleted)),
        );
      }
    }
  }

  Future<void> _holdRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => _HoldDialog(),
    );

    if (reason != null && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedRequest = await notifier.holdMaintenanceRequest(
        _request.id,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (updatedRequest != null && mounted) {
        setState(() {
          _request = updatedRequest;
        });
        ref.invalidate(maintenanceRequestsProvider);
        ref.invalidate(maintenanceRequestByIdProvider(_request.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requestOnHold)));
      }
    }
  }

  Future<void> _resumeRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.continueRequest),
        content: Text(l10n.continueRequestConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.resume),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedRequest = await notifier.resumeMaintenanceRequest(
        _request.id,
      );
      if (updatedRequest != null && mounted) {
        setState(() {
          _request = updatedRequest;
        });
        ref.invalidate(maintenanceRequestsProvider);
        ref.invalidate(maintenanceRequestByIdProvider(_request.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requestContinued)));
      }
    }
  }

  Future<void> _cancelRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelRequest),
        content: Text(l10n.cancelRequestConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.cancelRequest),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedRequest = await notifier.cancelMaintenanceRequest(
        _request.id,
      );
      if (updatedRequest != null && mounted) {
        setState(() {
          _request = updatedRequest;
        });
        ref.invalidate(maintenanceRequestsProvider);
        ref.invalidate(maintenanceRequestByIdProvider(_request.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requestCancelled)));
      }
    }
  }
}

class _CompletionDialog extends StatefulWidget {
  final MaintenanceRequest request;

  const _CompletionDialog({required this.request});

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.completeRequest),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.enterResolutionNotes),
          AppSpacing.gapVerticalMd,
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.describeWorkDone,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _notesController.text),
          child: Text(l10n.completed),
        ),
      ],
    );
  }
}

class _AssignDialog extends ConsumerStatefulWidget {
  final MaintenanceRequest request;

  const _AssignDialog({required this.request});

  @override
  ConsumerState<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<_AssignDialog> {
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.request.assignedTo;
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final currentUser = ref.watch(currentUserProvider);

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.assignRepair),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentUser != null)
              ListTile(
                onTap: () => setState(() => _selectedUserId = currentUser.id),
                selected: _selectedUserId == currentUser.id,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(AppLocalizations.of(context)!.selfAssign),
                subtitle: Text(currentUser.displayName),
                trailing: _selectedUserId == currentUser.id
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
            const Divider(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: staffAsync.when(
                data: (staffList) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    final isSelected = _selectedUserId == staff.id;
                    return ListTile(
                      onTap: () => setState(() => _selectedUserId = staff.id),
                      selected: isSelected,
                      leading: CircleAvatar(child: Text(staff.displayName[0])),
                      title: Text(staff.displayName),
                      subtitle: Text(
                        staff.roleDisplay ??
                            staff.role?.localizedName(context.l10n) ??
                            '',
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(AppLocalizations.of(context)!.staffLoadError),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _selectedUserId != null
              ? () => Navigator.pop(context, _selectedUserId)
              : null,
          child: Text(AppLocalizations.of(context)!.confirm),
        ),
      ],
    );
  }
}

class _HoldDialog extends StatefulWidget {
  @override
  State<_HoldDialog> createState() => _HoldDialogState();
}

class _HoldDialogState extends State<_HoldDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.holdRequest),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.enterHoldReason),
          AppSpacing.gapVerticalMd,
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n.reason,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _reasonController.text),
          child: Text(l10n.hold),
        ),
      ],
    );
  }
}
