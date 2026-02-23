import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/rate_plan.dart';
import '../../providers/rate_plan_provider.dart';
import '../../providers/room_provider.dart';

/// Pricing Management Screen with tabs for Rate Plans and Date Overrides
class PricingManagementScreen extends ConsumerStatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  ConsumerState<PricingManagementScreen> createState() =>
      _PricingManagementScreenState();
}

class _PricingManagementScreenState
    extends ConsumerState<PricingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedRoomTypeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roomTypesAsync = ref.watch(roomTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.priceManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.ratePlans, icon: const Icon(Icons.sell)),
            Tab(text: l10n.dailyRates, icon: const Icon(Icons.calendar_month)),
          ],
        ),
        actions: [
          // Room type filter
          roomTypesAsync.when(
            data: (roomTypes) => PopupMenuButton<int?>(
              icon: const Icon(Icons.filter_list),
              tooltip: l10n.filterByRoomType,
              onSelected: (value) {
                setState(() => _selectedRoomTypeId = value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: null, child: Text(l10n.allRoomTypes)),
                ...roomTypes.map(
                  (type) =>
                      PopupMenuItem(value: type.id, child: Text(type.name)),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RatePlansTab(roomTypeId: _selectedRoomTypeId),
          _DateOverridesTab(roomTypeId: _selectedRoomTypeId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/pricing/rate-plans/new');
          } else {
            context.push('/pricing/date-overrides/new');
          }
        },
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? l10n.addRatePlan : l10n.addDateRate,
        ),
      ),
    );
  }
}

/// Rate Plans Tab
class _RatePlansTab extends ConsumerWidget {
  final int? roomTypeId;

  const _RatePlansTab({this.roomTypeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratePlansAsync = roomTypeId != null
        ? ref.watch(ratePlansByRoomTypeProvider(roomTypeId!))
        : ref.watch(ratePlansProvider);

    return ratePlansAsync.when(
      data: (ratePlans) {
        if (ratePlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sell_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.gapVerticalMd,
                Text(
                  context.l10n.noRatePlansYet,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapVerticalSm,
                Text(
                  context.l10n.addRatePlanFlexiblePricing,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ratePlansProvider);
          },
          child: ListView.builder(
            padding: AppSpacing.paddingScreen,
            itemCount: ratePlans.length,
            itemBuilder: (context, index) {
              final plan = ratePlans[index];
              return _RatePlanCard(plan: plan);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            AppSpacing.gapVerticalMd,
            Text('${context.l10n.error}: $error'),
            AppSpacing.gapVerticalMd,
            ElevatedButton(
              onPressed: () => ref.invalidate(ratePlansProvider),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rate Plan Card
class _RatePlanCard extends ConsumerWidget {
  final RatePlanListItem plan;

  const _RatePlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/pricing/rate-plans/${plan.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (plan.roomTypeName != null)
                          Text(
                            plan.roomTypeName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: plan.isActive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.isActive
                          ? context.l10n.isActive
                          : context.l10n.pausedStatus,
                      style: TextStyle(
                        color: plan.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalMd,
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.attach_money,
                      label: currencyFormat.format(plan.baseRate),
                    ),
                  ),
                  if (plan.minStay > 1)
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.nights_stay,
                        label: context.l10n.minNightsStayDisplay.replaceAll(
                          '{count}',
                          '${plan.minStay}',
                        ),
                      ),
                    ),
                  if (plan.includesBreakfast)
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.free_breakfast,
                        label: context.l10n.includesBreakfastLabel,
                      ),
                    ),
                ],
              ),
              if (plan.validFrom != null || plan.validTo != null) ...[
                AppSpacing.gapVerticalSm,
                Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateRange(context, plan.validFrom, plan.validTo),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(BuildContext context, DateTime? from, DateTime? to) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    if (from != null && to != null) {
      return '${dateFormat.format(from)} - ${dateFormat.format(to)}';
    } else if (from != null) {
      return context.l10n.fromDateDisplay.replaceAll(
        '{date}',
        dateFormat.format(from),
      );
    } else if (to != null) {
      return context.l10n.toDateDisplay.replaceAll(
        '{date}',
        dateFormat.format(to),
      );
    }
    return '';
  }
}

/// Date Overrides Tab
class _DateOverridesTab extends ConsumerWidget {
  final int? roomTypeId;

  const _DateOverridesTab({this.roomTypeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overridesAsync = ref.watch(dateRateOverridesProvider);

    return overridesAsync.when(
      data: (overrides) {
        // Filter by room type if selected
        final filtered = roomTypeId != null
            ? overrides.where((o) => o.roomType == roomTypeId).toList()
            : overrides;

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.gapVerticalMd,
                Text(
                  context.l10n.noDailyRatesYet,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapVerticalSm,
                Text(
                  context.l10n.addSpecialRates,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Group by room type
        final groupedByRoomType = <int, List<DateRateOverrideListItem>>{};
        for (final item in filtered) {
          groupedByRoomType.putIfAbsent(item.roomType, () => []).add(item);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dateRateOverridesProvider);
          },
          child: ListView.builder(
            padding: AppSpacing.paddingScreen,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _DateOverrideCard(item: item);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            AppSpacing.gapVerticalMd,
            Text('${context.l10n.error}: $error'),
            AppSpacing.gapVerticalMd,
            ElevatedButton(
              onPressed: () => ref.invalidate(dateRateOverridesProvider),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Date Override Card
class _DateOverrideCard extends ConsumerWidget {
  final DateRateOverrideListItem item;

  const _DateOverrideCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/pricing/date-overrides/${item.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(item.date),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (item.roomTypeName != null)
                          Text(
                            item.roomTypeName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(item.rate),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (item.reason.isNotEmpty) ...[
                AppSpacing.gapVerticalSm,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.reason,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (item.closedToArrival || item.closedToDeparture) ...[
                AppSpacing.gapVerticalSm,
                Row(
                  children: [
                    if (item.closedToArrival)
                      _WarningChip(label: context.l10n.noArrivalsLabel),
                    if (item.closedToArrival && item.closedToDeparture)
                      const SizedBox(width: 8),
                    if (item.closedToDeparture)
                      _WarningChip(label: context.l10n.noDeparturesLabel),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Info Chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Warning Chip widget
class _WarningChip extends StatelessWidget {
  final String label;

  const _WarningChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber, size: 12, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
