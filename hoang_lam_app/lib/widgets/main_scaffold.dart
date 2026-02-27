import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../router/app_router.dart';
import '../l10n/app_localizations.dart';

/// Main scaffold with role-based bottom navigation
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: child, bottomNavigationBar: _RoleBasedBottomNav());
  }
}

/// Navigation destination definition
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

class _RoleBasedBottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final l10n = context.l10n;
    final currentUser = ref.watch(currentUserProvider);
    final role = currentUser?.role;

    final navItems = _getNavItems(l10n, role);
    final selectedIndex = _getSelectedIndex(location, navItems);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index < navItems.length) {
          context.go(navItems[index].route);
        }
      },
      destinations: navItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }

  List<_NavItem> _getNavItems(AppLocalizations l10n, UserRole? role) {
    switch (role) {
      case UserRole.housekeeping:
        // Housekeeping: Home | Tasks | Inspections | More | Settings
        return [
          _NavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l10n.home,
            route: AppRoutes.home,
          ),
          _NavItem(
            icon: Icons.cleaning_services_outlined,
            selectedIcon: Icons.cleaning_services,
            label: l10n.housekeepingTasks,
            route: AppRoutes.housekeepingTasks,
          ),
          _NavItem(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: l10n.roomInspection,
            route: AppRoutes.roomInspections,
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
            label: l10n.more,
            route: AppRoutes.more,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: l10n.settings,
            route: AppRoutes.settings,
          ),
        ];

      case UserRole.staff:
        // Staff: Home | Bookings | Housekeeping | More | Settings
        return [
          _NavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l10n.home,
            route: AppRoutes.home,
          ),
          _NavItem(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: l10n.bookings,
            route: AppRoutes.bookings,
          ),
          _NavItem(
            icon: Icons.cleaning_services_outlined,
            selectedIcon: Icons.cleaning_services,
            label: l10n.housekeepingTasks,
            route: AppRoutes.housekeepingTasks,
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
            label: l10n.more,
            route: AppRoutes.more,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: l10n.settings,
            route: AppRoutes.settings,
          ),
        ];

      case UserRole.owner:
      case UserRole.manager:
        // Owner/Manager: Home | Bookings | Finance | More | Settings
        return [
          _NavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l10n.home,
            route: AppRoutes.home,
          ),
          _NavItem(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: l10n.bookings,
            route: AppRoutes.bookings,
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet,
            label: l10n.finance,
            route: AppRoutes.finance,
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
            label: l10n.more,
            route: AppRoutes.more,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: l10n.settings,
            route: AppRoutes.settings,
          ),
        ];

      case null:
        // Unknown/null role: restrict to staff-level nav (no Finance)
        return [
          _NavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l10n.home,
            route: AppRoutes.home,
          ),
          _NavItem(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: l10n.bookings,
            route: AppRoutes.bookings,
          ),
          _NavItem(
            icon: Icons.cleaning_services_outlined,
            selectedIcon: Icons.cleaning_services,
            label: l10n.housekeepingTasks,
            route: AppRoutes.housekeepingTasks,
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
            label: l10n.more,
            route: AppRoutes.more,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: l10n.settings,
            route: AppRoutes.settings,
          ),
        ];
    }
  }

  int _getSelectedIndex(String location, List<_NavItem> navItems) {
    // Calendar view should highlight the Bookings tab
    if (location.startsWith(AppRoutes.bookingCalendar)) {
      for (int i = 0; i < navItems.length; i++) {
        if (navItems[i].route == AppRoutes.bookings) return i;
      }
    }

    // Check from the end to prefer more specific matches
    // (e.g., /bookings/new matches /bookings, not /home)
    for (int i = navItems.length - 1; i >= 0; i--) {
      if (location.startsWith(navItems[i].route)) {
        return i;
      }
    }
    return 0; // Default to Home
  }
}
