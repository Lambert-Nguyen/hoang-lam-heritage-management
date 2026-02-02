import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/housekeeping.dart';
import '../../providers/housekeeping_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

/// Screen showing detailed information about a maintenance request
class MaintenanceDetailScreen extends ConsumerStatefulWidget {
  final MaintenanceRequest request;

  const MaintenanceDetailScreen({
    super.key,
    required this.request,
  });

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
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Phòng ${_request.roomNumber ?? _request.room}'),
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
                const PopupMenuItem(
                  value: 'hold',
                  child: Row(
                    children: [
                      Icon(Icons.pause),
                      SizedBox(width: 8),
                      Text('Tạm hoãn'),
                    ],
                  ),
                ),
              if (_request.status == MaintenanceStatus.onHold)
                const PopupMenuItem(
                  value: 'resume',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('Tiếp tục'),
                    ],
                  ),
                ),
              if (_request.status.canCancel)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hủy', style: TextStyle(color: Colors.red)),
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
        border: Border.all(
          color: _request.status.color.withValues(alpha: 0.3),
        ),
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
            child: Icon(
              _request.status.icon,
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
                  _request.status.displayName,
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
            _request.priority.displayName,
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
            _request.category.displayName,
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin yêu cầu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            Icons.meeting_room,
            'Phòng',
            _request.roomNumber ?? 'Phòng ${_request.room}',
          ),
          _buildInfoRow(
            Icons.title,
            'Tiêu đề',
            _request.title,
          ),
          _buildInfoRow(
            Icons.category,
            'Danh mục',
            _request.category.displayName,
          ),
          _buildInfoRow(
            Icons.priority_high,
            'Mức ưu tiên',
            _request.priority.displayName,
          ),
          if (_request.estimatedCost != null)
            _buildInfoRow(
              Icons.attach_money,
              'Chi phí ước tính',
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(_request.estimatedCost),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phân công',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_request.status.canAssign)
                TextButton.icon(
                  onPressed: _assignRequest,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Phân công'),
                ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          if (_request.assignedTo != null) ...[
            _buildInfoRow(
              Icons.person,
              'Người thực hiện',
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
                    'Chưa được phân công',
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
              'Người báo cáo',
              _request.reportedByName ?? 'ID: ${_request.reportedBy}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              AppSpacing.gapHorizontalSm,
              Text(
                'Kết quả xử lý',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          if (_request.createdAt != null)
            _buildTimelineItem(
              'Tạo lúc',
              '${dateFormat.format(_request.createdAt!)} ${timeFormat.format(_request.createdAt!)}',
              Icons.add_circle_outline,
              AppColors.primary,
            ),
          if (_request.completedAt != null)
            _buildTimelineItem(
              'Hoàn thành lúc',
              '${dateFormat.format(_request.completedAt!)} ${timeFormat.format(_request.completedAt!)}',
              Icons.check_circle_outline,
              AppColors.success,
            ),
          if (_request.updatedAt != null &&
              _request.updatedAt != _request.createdAt)
            _buildTimelineItem(
              'Cập nhật lúc',
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
                  text: 'Phân công',
                  onPressed: _assignRequest,
                  variant: AppButtonVariant.outlined,
                  icon: Icons.person_add,
                ),
              ),
            if (_request.status.canAssign && _request.assignedTo == null)
              AppSpacing.gapHorizontalMd,
            if (_request.status.canComplete)
              Expanded(
                child: AppButton(
                  text: 'Hoàn thành',
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
    // Show assign dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng phân công đang phát triển')),
    );
  }

  Future<void> _completeRequest() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hoàn thành yêu cầu bảo trì')),
        );
      }
    }
  }

  Future<void> _holdRequest() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạm hoãn yêu cầu')),
        );
      }
    }
  }

  Future<void> _resumeRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tiếp tục yêu cầu'),
        content: const Text('Bạn có muốn tiếp tục xử lý yêu cầu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedRequest =
          await notifier.resumeMaintenanceRequest(_request.id);
      if (updatedRequest != null && mounted) {
        setState(() {
          _request = updatedRequest;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tiếp tục yêu cầu')),
        );
      }
    }
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy yêu cầu'),
        content: const Text('Bạn có chắc muốn hủy yêu cầu bảo trì này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      final updatedRequest =
          await notifier.cancelMaintenanceRequest(_request.id);
      if (updatedRequest != null && mounted) {
        setState(() {
          _request = updatedRequest;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy yêu cầu')),
        );
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
    return AlertDialog(
      title: const Text('Hoàn thành yêu cầu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhập ghi chú về kết quả xử lý (tùy chọn):'),
          AppSpacing.gapVerticalMd,
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Mô tả công việc đã thực hiện...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _notesController.text),
          child: const Text('Hoàn thành'),
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
    return AlertDialog(
      title: const Text('Tạm hoãn yêu cầu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhập lý do tạm hoãn (tùy chọn):'),
          AppSpacing.gapVerticalMd,
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Lý do...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _reasonController.text),
          child: const Text('Tạm hoãn'),
        ),
      ],
    );
  }
}
