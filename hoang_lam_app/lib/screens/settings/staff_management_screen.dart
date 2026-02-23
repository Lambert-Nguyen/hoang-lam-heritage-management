import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

/// Screen for viewing and managing staff accounts
class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  String _searchQuery = '';
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountManagement)),
      body: staffAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return _buildEmptyState(l10n);
          }
          return _buildContent(context, l10n, staffList);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(l10n, error),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
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

  Widget _buildErrorState(AppLocalizations l10n, Object error) {
    return Center(
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
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<User> staffList,
  ) {
    // Apply filters
    var filtered = staffList;
    if (_roleFilter != null) {
      filtered = filtered.where((u) => u.role == _roleFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (u) =>
                u.displayName.toLowerCase().contains(query) ||
                u.username.toLowerCase().contains(query) ||
                (u.phone ?? '').contains(query) ||
                (u.email ?? '').toLowerCase().contains(query),
          )
          .toList();
    }

    // Group by role
    final owners = filtered.where((u) => u.role == UserRole.owner).toList();
    final managers = filtered.where((u) => u.role == UserRole.manager).toList();
    final staff = filtered.where((u) => u.role == UserRole.staff).toList();
    final housekeeping = filtered
        .where((u) => u.role == UserRole.housekeeping)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(staffListProvider);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          // Role stats cards
          _buildRoleStats(context, staffList),

          // Search bar
          _buildSearchBar(),

          // Role filter chips
          _buildRoleFilterChips(staffList),

          // Results
          if (filtered.isEmpty) ...[
            AppSpacing.gapVerticalXl,
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  AppSpacing.gapVerticalSm,
                  Text(
                    context.l10n.noSearchResults,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],

          if (owners.isNotEmpty)
            _buildRoleSection(
              context,
              title: context.l10n.hotelOwner,
              icon: Icons.admin_panel_settings,
              color: AppColors.primary,
              users: owners,
            ),
          if (managers.isNotEmpty)
            _buildRoleSection(
              context,
              title: context.l10n.managerRole,
              icon: Icons.manage_accounts,
              color: AppColors.secondary,
              users: managers,
            ),
          if (staff.isNotEmpty)
            _buildRoleSection(
              context,
              title: context.l10n.staffRole,
              icon: Icons.person,
              color: AppColors.info,
              users: staff,
            ),
          if (housekeeping.isNotEmpty)
            _buildRoleSection(
              context,
              title: context.l10n.roleHousekeepingLabel,
              icon: Icons.cleaning_services,
              color: AppColors.cleaning,
              users: housekeeping,
            ),
        ],
      ),
    );
  }

  Widget _buildRoleStats(BuildContext context, List<User> staffList) {
    final roleCount = <UserRole, int>{};
    for (final user in staffList) {
      if (user.role != null) {
        roleCount[user.role!] = (roleCount[user.role!] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.groups,
              label: context.l10n.total,
              count: staffList.length,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.admin_panel_settings,
              label: context.l10n.ownerManagerFilter,
              count:
                  (roleCount[UserRole.owner] ?? 0) +
                  (roleCount[UserRole.manager] ?? 0),
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.person,
              label: context.l10n.staffRole,
              count: roleCount[UserRole.staff] ?? 0,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.cleaning_services,
              label: context.l10n.housekeepingShort,
              count: roleCount[UserRole.housekeeping] ?? 0,
              color: AppColors.cleaning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: context.l10n.searchStaffHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildRoleFilterChips(List<User> staffList) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(context.l10n.all),
            selected: _roleFilter == null,
            onSelected: (_) => setState(() => _roleFilter = null),
          ),
          ...UserRole.values.map((role) {
            final count = staffList.where((u) => u.role == role).length;
            if (count == 0) return const SizedBox.shrink();
            return ChoiceChip(
              label: Text('${role.localizedName(context.l10n)} ($count)'),
              selected: _roleFilter == role,
              onSelected: (_) => setState(() {
                _roleFilter = _roleFilter == role ? null : role;
              }),
            );
          }),
        ],
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
        ...users.map(
          (user) => _StaffTile(
            user: user,
            onTap: () => _showStaffDetailSheet(context, user),
          ),
        ),
        const Divider(),
      ],
    );
  }

  void _showStaffDetailSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _StaffDetailSheet(user: user),
    );
  }
}

// ============================================================
// Stat Card
// ============================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Staff Tile
// ============================================================

class _StaffTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _StaffTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'U';

    final roleColor = _getRoleColor(user.role);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: roleColor.withValues(alpha: 0.15),
        child: Text(
          initial,
          style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
        ),
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (user.roleDisplay != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.roleDisplay!,
                style: TextStyle(
                  fontSize: 11,
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(Icons.phone, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 2),
            Text(user.phone!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.textHint,
      ),
    );
  }
}

// ============================================================
// Staff Detail Bottom Sheet
// ============================================================

class _StaffDetailSheet extends StatelessWidget {
  final User user;

  const _StaffDetailSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'U';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Avatar + Name
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.roleDisplay ??
                          user.role?.localizedName(context.l10n) ??
                          context.l10n.staffRole,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Details
            _buildDetailRow(
              context,
              icon: Icons.person_outline,
              label: context.l10n.usernameLabel,
              value: user.username,
              canCopy: true,
            ),
            if (user.email != null && user.email!.isNotEmpty)
              _buildDetailRow(
                context,
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email!,
                canCopy: true,
              ),
            if (user.phone != null && user.phone!.isNotEmpty)
              _buildDetailRow(
                context,
                icon: Icons.phone_outlined,
                label: context.l10n.phoneNumber,
                value: user.phone!,
                canCopy: true,
              ),
            _buildDetailRow(
              context,
              icon: Icons.badge_outlined,
              label: 'ID',
              value: '#${user.id}',
            ),

            // Role permissions info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Card(
                color: AppColors.infoBackground,
                child: Padding(
                  padding: AppSpacing.paddingAll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, size: 16, color: AppColors.info),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.permissionsLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapVerticalSm,
                      ..._buildPermissionList(context, user.role),
                    ],
                  ),
                ),
              ),
            ),

            AppSpacing.gapVerticalMd,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: canCopy
          ? IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: context.l10n.copyTooltip,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${context.l10n.copiedValueMsg}: $value'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            )
          : null,
    );
  }

  List<Widget> _buildPermissionList(BuildContext context, UserRole? role) {
    final permissions = <_PermissionItem>[];

    switch (role) {
      case UserRole.owner:
        permissions.addAll([
          _PermissionItem(context.l10n.permViewAllData, true),
          _PermissionItem(context.l10n.permManageFinance, true),
          _PermissionItem(context.l10n.permManageBookings, true),
          _PermissionItem(context.l10n.permManageStaff, true),
          _PermissionItem(context.l10n.permEditRoomPrices, true),
          _PermissionItem(context.l10n.permNightAudit, true),
          _PermissionItem(context.l10n.permReportsStats, true),
        ]);
      case UserRole.manager:
        permissions.addAll([
          _PermissionItem(context.l10n.permViewAllData, true),
          _PermissionItem(context.l10n.permManageFinance, true),
          _PermissionItem(context.l10n.permManageBookings, true),
          _PermissionItem(context.l10n.permManageStaff, false),
          _PermissionItem(context.l10n.permEditRoomPrices, false),
          _PermissionItem(context.l10n.permNightAudit, true),
          _PermissionItem(context.l10n.permReportsStats, true),
        ]);
      case UserRole.staff:
        permissions.addAll([
          _PermissionItem(context.l10n.permViewBookings, true),
          _PermissionItem(context.l10n.permManageBookings, true),
          _PermissionItem(context.l10n.permManageFinance, false),
          _PermissionItem(context.l10n.permUpdateRoomStatus, true),
          _PermissionItem(context.l10n.permNightAudit, false),
          _PermissionItem(context.l10n.permReportsStats, false),
        ]);
      case UserRole.housekeeping:
        permissions.addAll([
          _PermissionItem(context.l10n.permViewRoomList, true),
          _PermissionItem(context.l10n.permUpdateCleaning, true),
          _PermissionItem(context.l10n.permReportMaintenance, true),
          _PermissionItem(context.l10n.permManageBookings, false),
          _PermissionItem(context.l10n.permManageFinance, false),
        ]);
      case null:
        permissions.add(
          _PermissionItem(context.l10n.noPermissionsAssigned, false),
        );
    }

    return permissions.map((p) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              p.granted ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: p.granted ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              p.name,
              style: TextStyle(
                fontSize: 13,
                color: p.granted ? null : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _PermissionItem {
  final String name;
  final bool granted;

  _PermissionItem(this.name, this.granted);
}

// ============================================================
// Shared Helpers
// ============================================================

Color _getRoleColor(UserRole? role) {
  switch (role) {
    case UserRole.owner:
      return AppColors.primary;
    case UserRole.manager:
      return AppColors.secondary;
    case UserRole.staff:
      return AppColors.info;
    case UserRole.housekeeping:
      return AppColors.cleaning;
    case null:
      return AppColors.textSecondary;
  }
}
