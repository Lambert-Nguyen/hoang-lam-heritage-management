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

/// Screen for viewing room inspection details
class RoomInspectionDetailScreen extends ConsumerWidget {
  final int inspectionId;

  const RoomInspectionDetailScreen({super.key, required this.inspectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inspectionAsync = ref.watch(roomInspectionByIdProvider(inspectionId));

    return inspectionAsync.when(
      data: (inspection) => _InspectionDetailContent(inspection: inspection),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.inspectionDetails)),
        body: const LoadingIndicator(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.inspectionDetails)),
        body: ErrorDisplay(
          message: '${l10n.error}: $e',
          onRetry: () => ref.invalidate(roomInspectionByIdProvider(inspectionId)),
        ),
      ),
    );
  }
}

class _InspectionDetailContent extends ConsumerStatefulWidget {
  final RoomInspection inspection;

  const _InspectionDetailContent({required this.inspection});

  @override
  ConsumerState<_InspectionDetailContent> createState() => _InspectionDetailContentState();
}

class _InspectionDetailContentState extends ConsumerState<_InspectionDetailContent> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inspection = widget.inspection;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.room} ${inspection.roomNumber}'),
        actions: [
          if (inspection.status == InspectionStatus.pending)
            TextButton.icon(
              onPressed: _isLoading ? null : _startInspection,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.start),
            ),
          if (inspection.status == InspectionStatus.inProgress)
            TextButton.icon(
              onPressed: () => context.push('/room-inspections/${inspection.id}/conduct'),
              icon: const Icon(Icons.checklist),
              label: Text(l10n.continueLabel),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: AppSpacing.paddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(context, inspection),
                  const SizedBox(height: AppSpacing.md),
                  if (inspection.status == InspectionStatus.completed ||
                      inspection.status == InspectionStatus.requiresAction) ...[
                    _buildScoreCard(context, inspection),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _buildChecklistCard(context, inspection),
                  const SizedBox(height: AppSpacing.md),
                  if (inspection.images.isNotEmpty) ...[
                    _buildImagesCard(context, inspection),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (inspection.notes.isNotEmpty) ...[
                    _buildNotesCard(context, inspection),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (inspection.actionRequired.isNotEmpty) ...[
                    _buildActionRequiredCard(context, inspection),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, RoomInspection inspection) {
    return AppCard(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inspection.inspectionType.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    inspection.inspectionType.icon,
                    color: inspection.inspectionType.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inspection.inspectionType.localizedName(context.l10n),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(context, inspection.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.calendar_today, context.l10n.scheduledDate, _formatDate(inspection.scheduledDate)),
            if (inspection.completedAt != null)
              _buildInfoRow(context, Icons.check_circle, context.l10n.completedLabel, _formatDateTime(inspection.completedAt!)),
            if (inspection.inspectorName != null)
              _buildInfoRow(context, Icons.person, context.l10n.inspector, inspection.inspectorName!),
            if (inspection.booking != null)
              _buildInfoRow(context, Icons.bookmark, context.l10n.bookingCodeLabel, '#${inspection.booking}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, RoomInspection inspection) {
    return AppCard(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.inspectionResult, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${inspection.score.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: _getScoreColor(inspection.score),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(context.l10n.scoreLabel),
                    ],
                  ),
                ),
                Container(width: 1, height: 60, color: AppColors.mutedAccent),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${inspection.passedItems}/${inspection.totalItems}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(context.l10n.passLabel),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: inspection.score / 100,
              backgroundColor: AppColors.mutedAccent,
              valueColor: AlwaysStoppedAnimation(_getScoreColor(inspection.score)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            if (inspection.issuesFound > 0 || inspection.criticalIssues > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (inspection.issuesFound > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${inspection.issuesFound} ${context.l10n.issuesCount}',
                            style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (inspection.criticalIssues > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, size: 16, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            '${inspection.criticalIssues} ${context.l10n.criticalIssuesLabel}',
                            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
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

  Widget _buildChecklistCard(BuildContext context, RoomInspection inspection) {
    return AppCard(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(context.l10n.checklistLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${inspection.passedItems}/${inspection.totalItems}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (inspection.checklistItems.isEmpty)
              Text(context.l10n.noChecklistItems)
            else
              ...inspection.checklistItems.map((checklistItem) => _buildChecklistItem(context, checklistItem)),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(BuildContext context, ChecklistItem checklistItem) {
    final isPassed = checklistItem.passed ?? false;
    final isChecked = checklistItem.passed != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isChecked
            ? (isPassed ? AppColors.success.withValues(alpha: 0.05) : AppColors.error.withValues(alpha: 0.05))
            : AppColors.mutedAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isChecked
              ? (isPassed ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3))
              : AppColors.mutedAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isChecked
                ? (isPassed ? Icons.check_circle : Icons.cancel)
                : Icons.radio_button_unchecked,
            color: isChecked ? (isPassed ? AppColors.success : AppColors.error) : AppColors.mutedAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checklistItem.item,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  checklistItem.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                if (checklistItem.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      checklistItem.notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          if (checklistItem.critical)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                context.l10n.critical,
                style: const TextStyle(fontSize: 10, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagesCard(BuildContext context, RoomInspection inspection) {
    return AppCard(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.l10n.imagesLabel} (${inspection.images.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: inspection.images.length,
                itemBuilder: (context, index) {
                  final imageUrl = inspection.images[index];
                  return GestureDetector(
                    onTap: () => _showImageDialog(context, imageUrl),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.mutedAccent),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported, color: AppColors.mutedAccent),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, RoomInspection inspection) {
    return AppCard(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, size: 20),
                const SizedBox(width: 8),
                Text(context.l10n.notesSection, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(inspection.notes),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRequiredCard(BuildContext context, RoomInspection inspection) {
    return AppCard(
      child: Container(
        padding: AppSpacing.paddingCard,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, size: 20, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  context.l10n.actionRequiredSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(inspection.actionRequired),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, InspectionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.localizedName(context.l10n),
            style: TextStyle(color: status.color, fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(context.l10n.viewPhoto),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.image_not_supported, size: 64)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startInspection() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(roomInspectionNotifierProvider.notifier).startInspection(widget.inspection.id);
      if (mounted) {
        context.push('/room-inspections/${widget.inspection.id}/conduct');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 90) {
      return AppColors.success;
    }
    if (score >= 70) {
      return AppColors.warning;
    }
    return AppColors.error;
  }
}
