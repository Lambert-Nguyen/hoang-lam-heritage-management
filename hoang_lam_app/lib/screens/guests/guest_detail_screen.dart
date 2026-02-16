import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
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
                  tooltip: context.l10n.edit,
                ),
                AppIconButton(
                  icon: Icons.more_vert,
                  onPressed: () => _showMoreActions(context),
                  tooltip: 'Menu',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeaderBackground(),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: context.l10n.info),
                  Tab(text: context.l10n.history),
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
          _buildStatsSection(),
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
            context.l10n.contactInfo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            Icons.phone,
            context.l10n.phoneNumber,
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
              context.l10n.address,
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
            context.l10n.identityDocument,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            _guest.idType.icon,
            context.l10n.documentType,
            _guest.idType.fullDisplayName,
          ),
          if (_guest.idNumber != null && _guest.idNumber!.isNotEmpty)
            _buildInfoRow(
              Icons.numbers,
              context.l10n.documentNumber,
              _guest.idNumber!,
              onCopy: () => _copyToClipboard(_guest.idNumber!),
            ),
          if (_guest.idIssuePlace.isNotEmpty)
            _buildInfoRow(
              Icons.place,
              context.l10n.issuedBy,
              _guest.idIssuePlace,
            ),
          if (_guest.idIssueDate != null)
            _buildInfoRow(
              Icons.calendar_today,
              context.l10n.issueDate,
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
            context.l10n.personalInfo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.gapVerticalMd,
          _buildInfoRow(
            Icons.flag,
            context.l10n.nationality,
            _guest.nationalityDisplay,
          ),
          if (_guest.gender != null)
            _buildInfoRow(
              _guest.gender!.icon,
              context.l10n.gender,
              _guest.gender!.localizedName(context.l10n),
            ),
          if (_guest.dateOfBirth != null) ...[
            _buildInfoRow(
              Icons.cake,
              context.l10n.dateOfBirth,
              _formatDate(_guest.dateOfBirth!),
            ),
            if (_guest.age != null)
              _buildInfoRow(
                Icons.person,
                context.l10n.age,
                '${_guest.age} ${context.l10n.yearsOld}',
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final historyAsync = ref.watch(guestHistoryProvider(_guest.id));
    final totalSpent = historyAsync.whenOrNull(data: (history) => history.totalSpent) ?? 0;
    return GuestStatsSummary(
      totalStays: _guest.totalStays,
      totalBookings: _guest.bookingCount,
      totalSpent: totalSpent,
      isVip: _guest.isVip,
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
                context.l10n.internalNotes,
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
          context.l10n.edit,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        AppSpacing.gapVerticalMd,
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: context.l10n.call,
                icon: Icons.phone,
                isOutlined: true,
                onPressed: () => _launchPhone(_guest.phone),
              ),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: AppButton(
                label: _guest.isVip ? context.l10n.removeVip : context.l10n.markVip,
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
      SnackBar(
        content: Text(context.l10n.copied),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.call}: $phone')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.call}: $phone')),
        );
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.of(context).push<Guest>(
      MaterialPageRoute(
        builder: (_) => GuestFormScreen(guest: _guest),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _guest = result;
      });
      ref.invalidate(guestsProvider);
      ref.invalidate(guestByIdProvider(_guest.id));
    }
  }

  Future<void> _toggleVipStatus() async {
    final result =
        await ref.read(guestStateProvider.notifier).toggleVipStatus(_guest.id);
    if (result != null && mounted) {
      setState(() {
        _guest = result;
      });
      ref.invalidate(guestsProvider);
      ref.invalidate(guestByIdProvider(_guest.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isVip
                ? '${_guest.fullName} ${context.l10n.markedAsVip}'
                : '${_guest.fullName} ${context.l10n.vipRemoved}',
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
              title: Text(context.l10n.editInfo),
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
              title: Text(_guest.isVip ? context.l10n.removeVip : context.l10n.markVip),
              onTap: () {
                Navigator.pop(context);
                _toggleVipStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(context.l10n.call),
              onTap: () {
                Navigator.pop(context);
                _launchPhone(_guest.phone);
              },
            ),
            if (_guest.bookingCount == 0)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  context.l10n.deleteGuest,
                  style: const TextStyle(color: AppColors.error),
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
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(
          '${context.l10n.confirmDeleteGuest} "${_guest.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(guestStateProvider.notifier)
                  .deleteGuest(_guest.id);
              if (success && mounted) {
                ref.invalidate(guestsProvider);
                Navigator.of(this.context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.guestDeleted),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(
              context.l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
