import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/lost_found.dart';
import '../../providers/lost_found_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen for displaying lost & found item details
class LostFoundDetailScreen extends ConsumerStatefulWidget {
  final int itemId;
  const LostFoundDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<LostFoundDetailScreen> createState() => _LostFoundDetailScreenState();
}

class _LostFoundDetailScreenState extends ConsumerState<LostFoundDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(lostFoundItemByIdProvider(widget.itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đồ thất lạc'),
        actions: [
          itemAsync.whenOrNull(
            data: (item) => PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Sửa'), contentPadding: EdgeInsets.zero)),
                if (item.status == LostFoundStatus.found)
                  const PopupMenuItem(value: 'store', child: ListTile(leading: Icon(Icons.archive), title: Text('Lưu kho'), contentPadding: EdgeInsets.zero)),
                if (item.status == LostFoundStatus.found || item.status == LostFoundStatus.stored)
                  const PopupMenuItem(value: 'claim', child: ListTile(leading: Icon(Icons.check_circle), title: Text('Đã nhận'), contentPadding: EdgeInsets.zero)),
                if (item.status == LostFoundStatus.stored)
                  const PopupMenuItem(value: 'dispose', child: ListTile(leading: Icon(Icons.delete_forever), title: Text('Xử lý'), contentPadding: EdgeInsets.zero)),
              ],
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: itemAsync.when(
        data: (item) => _buildContent(item),
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: 'Không thể tải: $e', onRetry: () => ref.invalidate(lostFoundItemByIdProvider(widget.itemId))),
      ),
      bottomNavigationBar: itemAsync.whenOrNull(data: (item) => _buildBottomBar(item)),
    );
  }

  Widget _buildContent(LostFoundItem item) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(color: item.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(item.status.icon, size: 16, color: item.status.color),
                  const SizedBox(width: 4),
                  Text(item.status.displayName, style: TextStyle(color: item.status.color, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(color: item.category.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(item.category.icon, size: 16, color: item.category.color),
                  const SizedBox(width: 4),
                  Text(item.category.displayName, style: TextStyle(color: item.category.color)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.itemName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          if (item.description.isNotEmpty) ...[
            _SectionCard(title: 'Mô tả', icon: Icons.description, child: Text(item.description)),
            const SizedBox(height: AppSpacing.md),
          ],
          _SectionCard(
            title: 'Vị trí',
            icon: Icons.location_on,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.roomNumber != null) _InfoRow(label: 'Phòng', value: item.roomNumber!),
                if (item.foundLocation.isNotEmpty) _InfoRow(label: 'Nơi tìm thấy', value: item.foundLocation),
                if (item.storageLocation.isNotEmpty) _InfoRow(label: 'Nơi lưu trữ', value: item.storageLocation),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Thời gian',
            icon: Icons.calendar_today,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Ngày tìm thấy', value: _formatDate(item.foundDate)),
                if (item.claimedDate != null) _InfoRow(label: 'Ngày nhận', value: _formatDate(item.claimedDate!)),
              ],
            ),
          ),
          if (item.guestName != null) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Khách hàng',
              icon: Icons.person,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Tên', value: item.guestName!),
                  _InfoRow(label: 'Đã liên hệ', value: item.guestContacted ? 'Có' : 'Chưa'),
                ],
              ),
            ),
          ],
          if (item.estimatedValue != null) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Giá trị ước tính',
              icon: Icons.attach_money,
              child: Text('${item.estimatedValue!.toStringAsFixed(0)}₫', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildBottomBar(LostFoundItem item) {
    if (item.status == LostFoundStatus.claimed || item.status == LostFoundStatus.donated || item.status == LostFoundStatus.disposed) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: Padding(
        padding: AppSpacing.paddingAll,
        child: Row(
          children: [
            if (item.status == LostFoundStatus.found) ...[
              Expanded(child: AppButton(label: 'Lưu kho', onPressed: _isLoading ? null : () => _storeItem(item), isOutlined: true, icon: Icons.archive)),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: AppButton(label: 'Đã nhận', onPressed: _isLoading ? null : () => _claimItem(item), icon: Icons.check_circle, isLoading: _isLoading)),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, LostFoundItem item) {
    switch (action) {
      case 'edit':
        context.push('/lost-found/${item.id}/edit');
      case 'store':
        _storeItem(item);
      case 'claim':
        _claimItem(item);
      case 'dispose':
        _disposeItem(item);
    }
  }

  Future<void> _storeItem(LostFoundItem item) async {
    final location = await _showInputDialog('Nơi lưu trữ', 'VD: Tủ đồ thất lạc');
    if (location == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(lostFoundNotifierProvider.notifier).storeItem(item.id, storageLocation: location);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu vào kho')));
        ref.invalidate(lostFoundItemByIdProvider(widget.itemId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimItem(LostFoundItem item) async {
    final confirmed = await _showConfirmDialog('Xác nhận', 'Xác nhận khách đã nhận lại đồ?');
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(lostFoundNotifierProvider.notifier).claimItem(item.id);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đánh dấu là đã nhận')));
        ref.invalidate(lostFoundItemByIdProvider(widget.itemId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disposeItem(LostFoundItem item) async {
    final reason = await _showInputDialog('Lý do xử lý', 'Nhập lý do xử lý/quyên góp');
    if (reason == null || reason.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(lostFoundNotifierProvider.notifier).disposeItem(item.id, reason: reason);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xử lý đồ vật')));
        ref.invalidate(lostFoundItemByIdProvider(widget.itemId));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showInputDialog(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Lưu')),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );
  }

  String _formatDate(String d) {
    try {
      final date = DateTime.parse(d);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return d;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
