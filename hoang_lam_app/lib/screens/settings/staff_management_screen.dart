import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

/// Screen for viewing and managing staff accounts
class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountManagement),
      ),
      body: staffAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  AppSpacing.gapVerticalMd,
                  Text(
                    l10n.noData,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group by role
          final owners =
              staffList.where((u) => u.role == UserRole.owner).toList();
          final managers =
              staffList.where((u) => u.role == UserRole.manager).toList();
          final staff =
              staffList.where((u) => u.role == UserRole.staff).toList();
          final housekeeping =
              staffList.where((u) => u.role == UserRole.housekeeping).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(staffListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                // Summary card
                _buildSummaryCard(context, staffList),
                AppSpacing.gapVerticalMd,

                if (owners.isNotEmpty)
                  _buildRoleSection(
                    context,
                    title: 'Chủ khách sạn',
                    icon: Icons.admin_panel_settings,
                    color: AppColors.primary,
                    users: owners,
                  ),
                if (managers.isNotEmpty)
                  _buildRoleSection(
                    context,
                    title: 'Quản lý',
                    icon: Icons.manage_accounts,
                    color: AppColors.secondary,
                    users: managers,
                  ),
                if (staff.isNotEmpty)
                  _buildRoleSection(
                    context,
                    title: 'Nhân viên',
                    icon: Icons.person,
                    color: AppColors.info,
                    users: staff,
                  ),
                if (housekeeping.isNotEmpty)
                  _buildRoleSection(
                    context,
                    title: 'Phòng buồng',
                    icon: Icons.cleaning_services,
                    color: AppColors.cleaning,
                    users: housekeeping,
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              AppSpacing.gapVerticalMd,
              Text('${l10n.error}: $error'),
              AppSpacing.gapVerticalMd,
              ElevatedButton(
                onPressed: () => ref.invalidate(staffListProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<User> staffList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingAll,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups,
                  color: AppColors.primary,
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng nhân sự',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${staffList.length} tài khoản',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<User> users,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                '$title (${users.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        ...users.map((user) => _StaffTile(user: user)),
        const Divider(),
      ],
    );
  }
}

class _StaffTile extends StatelessWidget {
  final User user;

  const _StaffTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial =
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U';

    Color roleColor;
    switch (user.role) {
      case UserRole.owner:
        roleColor = AppColors.primary;
      case UserRole.manager:
        roleColor = AppColors.secondary;
      case UserRole.staff:
        roleColor = AppColors.info;
      case UserRole.housekeeping:
        roleColor = AppColors.cleaning;
      case null:
        roleColor = AppColors.textSecondary;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: roleColor.withValues(alpha: 0.15),
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: roleColor,
          ),
        ),
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.roleDisplay != null)
            Text(
              user.roleDisplay!,
              style: TextStyle(
                fontSize: 12,
                color: roleColor,
              ),
            ),
          if (user.phone != null && user.phone!.isNotEmpty)
            Text(
              user.phone!,
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (user.email != null && user.email!.isNotEmpty)
            Text(
              user.email!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
