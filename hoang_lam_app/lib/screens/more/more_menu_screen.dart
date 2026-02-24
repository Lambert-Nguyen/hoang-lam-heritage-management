import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';

/// More menu screen — grid of all features, role-filtered
class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentUser = ref.watch(currentUserProvider);
    final role = currentUser?.role;

    final menuItems = _buildMenuItems(l10n, role);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.allFeatures)),
      body: GridView.builder(
        padding: AppSpacing.paddingScreen,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.0,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _MenuTile(
            icon: item.icon,
            label: item.label,
            color: item.color,
            onTap: () => context.push(item.route),
          );
        },
      ),
    );
  }

  List<_MenuItem> _buildMenuItems(AppLocalizations l10n, UserRole? role) {
    final items = <_MenuItem>[];

    // Bookings — always available for non-housekeeping
    if (role?.canManageBookings ?? true) {
      items.add(
        _MenuItem(
          icon: Icons.calendar_month,
          label: l10n.bookings,
          route: AppRoutes.bookings,
          color: AppColors.primary,
        ),
      );
      items.add(
        _MenuItem(
          icon: Icons.group,
          label: l10n.groupBooking,
          route: AppRoutes.groupBookings,
          color: Colors.indigo,
        ),
      );
    }

    // Housekeeping — available to all roles
    items.add(
      _MenuItem(
        icon: Icons.cleaning_services,
        label: l10n.housekeepingTasks,
        route: AppRoutes.housekeepingTasks,
        color: Colors.teal,
      ),
    );

    // Maintenance
    items.add(
      _MenuItem(
        icon: Icons.build,
        label: l10n.maintenance,
        route: AppRoutes.maintenance,
        color: Colors.orange,
      ),
    );

    // Room Management
    items.add(
      _MenuItem(
        icon: Icons.meeting_room,
        label: l10n.roomManagement,
        route: AppRoutes.roomManagement,
        color: Colors.blue,
      ),
    );

    // Room Inspections
    items.add(
      _MenuItem(
        icon: Icons.checklist,
        label: l10n.roomInspection,
        route: AppRoutes.roomInspections,
        color: Colors.deepPurple,
      ),
    );

    // Minibar POS
    items.add(
      _MenuItem(
        icon: Icons.local_bar,
        label: l10n.minibarManagement,
        route: AppRoutes.minibarPos,
        color: Colors.pink,
      ),
    );

    // Lost & Found
    items.add(
      _MenuItem(
        icon: Icons.inventory_2,
        label: l10n.lostAndFound,
        route: AppRoutes.lostFound,
        color: Colors.brown,
      ),
    );

    // Finance — admin only
    if (role?.canViewFinance ?? false) {
      items.add(
        _MenuItem(
          icon: Icons.account_balance_wallet,
          label: l10n.finance,
          route: AppRoutes.finance,
          color: Colors.green,
        ),
      );
      items.add(
        _MenuItem(
          icon: Icons.nightlight,
          label: l10n.nightAudit,
          route: AppRoutes.nightAudit,
          color: Colors.blueGrey,
        ),
      );
      items.add(
        _MenuItem(
          icon: Icons.bar_chart,
          label: l10n.reports,
          route: AppRoutes.reports,
          color: Colors.amber,
        ),
      );
      items.add(
        _MenuItem(
          icon: Icons.description,
          label: l10n.residenceDeclaration,
          route: AppRoutes.declaration,
          color: Colors.lime,
        ),
      );
    }

    // Pricing — owner only
    if (role?.canEditRates ?? false) {
      items.add(
        _MenuItem(
          icon: Icons.sell,
          label: l10n.priceManagement,
          route: AppRoutes.pricing,
          color: Colors.deepOrange,
        ),
      );
    }

    return items;
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
