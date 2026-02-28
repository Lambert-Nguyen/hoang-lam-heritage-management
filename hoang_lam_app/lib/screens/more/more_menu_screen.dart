import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';

/// More menu screen — grid of all features, role-filtered, with category sections
class MoreMenuScreen extends ConsumerStatefulWidget {
  const MoreMenuScreen({super.key});

  @override
  ConsumerState<MoreMenuScreen> createState() => _MoreMenuScreenState();
}

class _MoreMenuScreenState extends ConsumerState<MoreMenuScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentUser = ref.watch(currentUserProvider);
    final role = currentUser?.role;

    final allSections = _buildMenuSections(l10n, role);

    // Filter sections based on search query
    final sections = _searchQuery.isEmpty
        ? allSections
        : _filterSections(allSections, _searchQuery);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.allFeatures)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchFeatures,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
          ),
          Expanded(
            child: sections.isEmpty
                ? Center(
                    child: Text(
                      l10n.noResultsFound,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index > 0) const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              section.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.0,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: section.items
                                .map(
                                  (item) => _MenuTile(
                                    icon: item.icon,
                                    label: item.label,
                                    color: item.color,
                                    onTap: () => context.push(item.route),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<_MenuSection> _filterSections(
    List<_MenuSection> sections,
    String query,
  ) {
    final lowerQuery = query.toLowerCase();
    final filtered = <_MenuSection>[];
    for (final section in sections) {
      final matchingItems = section.items
          .where((item) => item.label.toLowerCase().contains(lowerQuery))
          .toList();
      if (matchingItems.isNotEmpty) {
        filtered.add(_MenuSection(title: section.title, items: matchingItems));
      }
    }
    return filtered;
  }

  static List<_MenuSection> _buildMenuSections(AppLocalizations l10n, UserRole? role) {
    final sections = <_MenuSection>[];

    // Booking Management section
    if (role?.canManageBookings ?? true) {
      sections.add(
        _MenuSection(
          title: l10n.bookingManagementCategory,
          items: [
            _MenuItem(
              icon: Icons.calendar_month,
              label: l10n.bookings,
              route: AppRoutes.bookings,
              color: AppColors.primary,
            ),
            _MenuItem(
              icon: Icons.group,
              label: l10n.groupBooking,
              route: AppRoutes.groupBookings,
              color: Colors.indigo,
            ),
            _MenuItem(
              icon: Icons.person_search,
              label: l10n.guestManagement,
              route: AppRoutes.guests,
              color: Colors.cyan,
            ),
          ],
        ),
      );
    }

    // Operations section
    final operationsItems = <_MenuItem>[
      _MenuItem(
        icon: Icons.cleaning_services,
        label: l10n.housekeepingTasks,
        route: AppRoutes.housekeepingTasks,
        color: Colors.teal,
      ),
      _MenuItem(
        icon: Icons.build,
        label: l10n.maintenance,
        route: AppRoutes.maintenance,
        color: Colors.orange,
      ),
      _MenuItem(
        icon: Icons.meeting_room,
        label: l10n.roomManagement,
        route: AppRoutes.roomManagement,
        color: Colors.blue,
      ),
      _MenuItem(
        icon: Icons.checklist,
        label: l10n.roomInspection,
        route: AppRoutes.roomInspections,
        color: Colors.deepPurple,
      ),
      _MenuItem(
        icon: Icons.local_bar,
        label: l10n.minibarManagement,
        route: AppRoutes.minibarPos,
        color: Colors.pink,
      ),
      _MenuItem(
        icon: Icons.inventory_2,
        label: l10n.lostAndFound,
        route: AppRoutes.lostFound,
        color: Colors.brown,
      ),
    ];
    sections.add(
      _MenuSection(title: l10n.operationsCategory, items: operationsItems),
    );

    // Admin & Reports section
    if (role?.canViewFinance ?? false) {
      final adminItems = <_MenuItem>[
        _MenuItem(
          icon: Icons.account_balance_wallet,
          label: l10n.finance,
          route: AppRoutes.finance,
          color: Colors.green,
        ),
        _MenuItem(
          icon: Icons.nightlight,
          label: l10n.nightAudit,
          route: AppRoutes.nightAudit,
          color: Colors.blueGrey,
        ),
        _MenuItem(
          icon: Icons.bar_chart,
          label: l10n.reports,
          route: AppRoutes.reports,
          color: Colors.amber,
        ),
        _MenuItem(
          icon: Icons.description,
          label: l10n.residenceDeclaration,
          route: AppRoutes.declaration,
          color: Colors.lime,
        ),
      ];

      adminItems.add(
        _MenuItem(
          icon: Icons.history,
          label: l10n.auditLog,
          route: AppRoutes.auditLog,
          color: Colors.grey,
        ),
      );

      // Pricing — owner only
      if (role?.canEditRates ?? false) {
        adminItems.add(
          _MenuItem(
            icon: Icons.sell,
            label: l10n.priceManagement,
            route: AppRoutes.pricing,
            color: Colors.deepOrange,
          ),
        );
      }

      sections.add(
        _MenuSection(title: l10n.adminReportsCategory, items: adminItems),
      );
    }

    return sections;
  }
}

class _MenuSection {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});
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
