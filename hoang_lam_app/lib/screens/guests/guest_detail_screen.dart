import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/guests/guest_history_widget.dart';
import 'guest_form_screen.dart';

/// Screen showing detailed information about a single guest
class GuestDetailScreen extends ConsumerStatefulWidget {
  final Guest guest;

  const GuestDetailScreen({
    super.key,
    required this.guest,
  });

  @override
  ConsumerState<GuestDetailScreen> createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends ConsumerState<GuestDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Guest _guest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _guest = widget.guest;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              actions: [
                AppIconButton(
                  icon: Icons.edit,
                  onPressed: _navigateToEdit,
                  tooltip: 'Chỉnh sửa',
                ),
                AppIconButton(
                  icon: Icons.more_vert,
                  onPressed: () => _showMoreActions(context),
                  tooltip: 'Thêm',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeaderBackground(),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Thông tin'),
                  Tab(text: 'Lịch sử'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _guest.isVip
                ? AppColors.warning.withValues(alpha: 0.8)
                : AppColors.primary.withValues(alpha: 0.8),
            _guest.isVip
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSpacing.gapVerticalXl,
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Text(
                  _guest.initials,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _guest.isVip ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.gapVerticalSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _guest.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  if (_guest.isVip) ...[
                    AppSpacing.gapHorizontalSm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.warning),
                          SizedBox(width: 2),
                          Text(
                            'VIP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              AppSpacing.gapVerticalXs,
              Text(
                _guest.formattedPhone,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact information
          _buildContactSection(),
          AppSpacing.gapVerticalLg,

          // ID information
          _buildIdSection(),
          AppSpacing.gapVerticalLg,

          // Personal information
          _buildPersonalSection(),
          AppSpacing.gapVerticalLg,

          // Stats section
          GuestStatsSummary(
            totalStays: _guest.totalStays,
            totalBookings: _guest.bookingCount,
            totalSpent: 0,
            isVip: _guest.isVip,
          ),
          AppSpacing.gapVerticalLg,

          // Notes section
          if (_guest.notes.isNotEmpty) ...[
            _buildNotesSection(),
            AppSpacing.gapVerticalLg,
          ],

          // Quick actions
          _buildQuickActions(),
          AppSpacing.gapVerticalXl,
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin liên hệ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            Icons.phone,
            'Số điện thoại',
            _guest.formattedPhone,
            onCopy: () => _copyToClipboard(_guest.phone),
          ),
          if (_guest.email.isNotEmpty)
            _buildInfoRow(
              Icons.email,
              'Email',
              _guest.email,
              onCopy: () => _copyToClipboard(_guest.email),
            ),
          if (_guest.address.isNotEmpty)
            _buildInfoRow(
              Icons.location_on,
              'Địa chỉ',
              [_guest.address, _guest.city, _guest.country]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
            ),
        ],
      ),
    );
  }

  Widget _buildIdSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giấy tờ tùy thân',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            _guest.idType.icon,
            'Loại giấy tờ',
            _guest.idType.fullDisplayName,
          ),
          if (_guest.idNumber != null && _guest.idNumber!.isNotEmpty)
            _buildInfoRow(
              Icons.numbers,
              'Số giấy tờ',
              _guest.idNumber!,
              onCopy: () => _copyToClipboard(_guest.idNumber!),
            ),
          if (_guest.idIssuePlace.isNotEmpty)
            _buildInfoRow(
              Icons.place,
              'Nơi cấp',
              _guest.idIssuePlace,
            ),
          if (_guest.idIssueDate != null)
            _buildInfoRow(
              Icons.calendar_today,
              'Ngày cấp',
              _formatDate(_guest.idIssueDate!),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cá nhân',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            Icons.flag,
            'Quốc tịch',
            _guest.nationalityDisplay,
          ),
          if (_guest.gender != null)
            _buildInfoRow(
              _guest.gender!.icon,
              'Giới tính',
              _guest.gender!.displayName,
            ),
          if (_guest.dateOfBirth != null) ...[
            _buildInfoRow(
              Icons.cake,
              'Ngày sinh',
              _formatDate(_guest.dateOfBirth!),
            ),
            if (_guest.age != null)
              _buildInfoRow(
                Icons.person,
                'Tuổi',
                '${_guest.age} tuổi',
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, size: 20, color: AppColors.textSecondary),
              AppSpacing.gapHorizontalSm,
              Text(
                'Ghi chú',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Text(
            _guest.notes,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        AppSpacing.gapVerticalMd,
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Gọi điện',
                icon: Icons.phone,
                isOutlined: true,
                onPressed: () => _launchPhone(_guest.phone),
              ),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: AppButton(
                label: _guest.isVip ? 'Bỏ VIP' : 'Đánh dấu VIP',
                icon: _guest.isVip ? Icons.star_border : Icons.star,
                isOutlined: true,
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.warning,
                onPressed: _toggleVipStatus,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          AppSpacing.gapHorizontalSm,
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: AppColors.textHint,
              onPressed: onCopy,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return GuestHistoryWidget(guestId: _guest.id);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _launchPhone(String phone) {
    // TODO: Implement phone launch using url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gọi điện: $phone')),
    );
  }

  void _navigateToEdit() async {
    final result = await Navigator.of(context).push<Guest>(
      MaterialPageRoute(
        builder: (_) => GuestFormScreen(guest: _guest),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _guest = result;
      });
    }
  }

  void _toggleVipStatus() async {
    final result =
        await ref.read(guestStateProvider.notifier).toggleVipStatus(_guest.id);
    if (result != null && mounted) {
      setState(() {
        _guest = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isVip
                ? '${_guest.fullName} đã được đánh dấu VIP'
                : '${_guest.fullName} đã bỏ đánh dấu VIP',
          ),
          backgroundColor: result.isVip ? AppColors.warning : AppColors.success,
        ),
      );
    }
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa thông tin'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEdit();
              },
            ),
            ListTile(
              leading: Icon(
                _guest.isVip ? Icons.star_border : Icons.star,
                color: AppColors.warning,
              ),
              title: Text(_guest.isVip ? 'Bỏ VIP' : 'Đánh dấu VIP'),
              onTap: () {
                Navigator.pop(context);
                _toggleVipStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Gọi điện'),
              onTap: () {
                Navigator.pop(context);
                _launchPhone(_guest.phone);
              },
            ),
            if (_guest.bookingCount == 0)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  'Xóa khách hàng',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa khách hàng "${_guest.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(guestStateProvider.notifier)
                  .deleteGuest(_guest.id);
              if (success && mounted) {
                Navigator.of(this.context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa khách hàng'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
