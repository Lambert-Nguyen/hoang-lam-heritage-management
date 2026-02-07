import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/guests/guest_card.dart';
import 'guest_detail_screen.dart';
import 'guest_form_screen.dart';

/// Main screen for displaying and managing guests
class GuestListScreen extends ConsumerStatefulWidget {
  const GuestListScreen({super.key});

  @override
  ConsumerState<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends ConsumerState<GuestListScreen> {
  final _searchController = TextEditingController();
  String _searchType = 'all';
  bool _showVipOnly = false;
  String? _selectedNationality;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.guests),
        actions: [
          AppIconButton(
            icon: Icons.filter_list,
            onPressed: _showFilterSheet,
            tooltip: context.l10n.filter,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildGuestList()),
        ],
      ),
      floatingActionButton: AppFab(
        icon: Icons.person_add,
        tooltip: context.l10n.addGuest,
        onPressed: () => _navigateToForm(context),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.l10n.searchGuests,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().length >= 2) {
      ref.read(guestStateProvider.notifier).searchGuests(
            query.trim(),
            searchBy: _searchType,
          );
    } else if (query.isEmpty) {
      ref.read(guestStateProvider.notifier).loadGuests(
            isVip: _showVipOnly ? true : null,
            nationality: _selectedNationality,
          );
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _FilterChip(
            label: context.l10n.all,
            isSelected: _searchType == 'all',
            onTap: () => setState(() => _searchType = 'all'),
          ),
          AppSpacing.gapHorizontalSm,
          _FilterChip(
            label: context.l10n.name,
            isSelected: _searchType == 'name',
            onTap: () => setState(() => _searchType = 'name'),
          ),
          AppSpacing.gapHorizontalSm,
          _FilterChip(
            label: context.l10n.phoneNumber,
            isSelected: _searchType == 'phone',
            onTap: () => setState(() => _searchType = 'phone'),
          ),
          AppSpacing.gapHorizontalSm,
          _FilterChip(
            label: context.l10n.documentNumber,
            isSelected: _searchType == 'id_number',
            onTap: () => setState(() => _searchType = 'id_number'),
          ),
          AppSpacing.gapHorizontalMd,
          const VerticalDivider(width: 1),
          AppSpacing.gapHorizontalMd,
          _FilterChip(
            label: 'VIP',
            icon: Icons.star,
            iconColor: AppColors.warning,
            isSelected: _showVipOnly,
            onTap: () {
              setState(() => _showVipOnly = !_showVipOnly);
              _performSearch(_searchController.text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuestList() {
    final guestState = ref.watch(guestStateProvider);

    return guestState.when(
      initial: () {
        // Load guests on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(guestStateProvider.notifier).loadGuests();
        });
        return const Center(child: CircularProgressIndicator());
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      loaded: (guests) => _buildGuestListView(guests),
      success: (guest, message) {
        // Reload list after success
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(guestStateProvider.notifier).loadGuests();
        });
        return const Center(child: CircularProgressIndicator());
      },
      error: (message) => _buildErrorState(message),
    );
  }

  Widget _buildGuestListView(List<Guest> guests) {
    if (guests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(guestStateProvider.notifier).loadGuests(
              isVip: _showVipOnly ? true : null,
              nationality: _selectedNationality,
            );
      },
      child: ListView.separated(
        padding: AppSpacing.paddingScreen,
        itemCount: guests.length,
        separatorBuilder: (_, __) => AppSpacing.gapVerticalSm,
        itemBuilder: (context, index) {
          final guest = guests[index];
          return GuestCard(
            guest: guest,
            onTap: () => _navigateToDetail(context, guest),
            onLongPress: () => _showGuestActions(context, guest),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _showVipOnly ||
        _selectedNationality != null ||
        _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: AppColors.textHint,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              hasFilters
                  ? context.l10n.guestNotFound
                  : context.l10n.noGuestsYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              hasFilters
                  ? context.l10n.tryDifferentSearch
                  : context.l10n.pressToAddGuest,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            AppSpacing.gapVerticalLg,
            AppButton(
              label: context.l10n.retry,
              icon: Icons.refresh,
              onPressed: () {
                ref.read(guestStateProvider.notifier).loadGuests();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Guest guest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuestDetailScreen(guest: guest),
      ),
    );
  }

  void _navigateToForm(BuildContext context, [Guest? guest]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuestFormScreen(guest: guest),
      ),
    );
  }

  void _showGuestActions(BuildContext context, Guest guest) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text(context.l10n.viewBookingDetails),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(context, guest);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(context.l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _navigateToForm(context, guest);
              },
            ),
            ListTile(
              leading: Icon(
                guest.isVip ? Icons.star_border : Icons.star,
                color: AppColors.warning,
              ),
              title: Text(guest.isVip ? context.l10n.removeVip : context.l10n.markVip),
              onTap: () {
                Navigator.pop(context);
                _toggleVipStatus(guest);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(context.l10n.history),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(context, guest);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVipStatus(Guest guest) async {
    final result =
        await ref.read(guestStateProvider.notifier).toggleVipStatus(guest.id);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isVip
                ? '${guest.fullName} ${context.l10n.markedAsVip}'
                : '${guest.fullName} ${context.l10n.vipRemoved}',
          ),
          backgroundColor: result.isVip ? AppColors.warning : AppColors.success,
        ),
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        showVipOnly: _showVipOnly,
        selectedNationality: _selectedNationality,
        onApply: (vipOnly, nationality) {
          setState(() {
            _showVipOnly = vipOnly;
            _selectedNationality = nationality;
          });
          Navigator.pop(context);
          _performSearch(_searchController.text);
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: iconColor ?? (isSelected ? AppColors.primary : null),
              ),
              AppSpacing.gapHorizontalXs,
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final bool showVipOnly;
  final String? selectedNationality;
  final void Function(bool vipOnly, String? nationality) onApply;

  const _FilterSheet({
    required this.showVipOnly,
    this.selectedNationality,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _vipOnly;
  late String? _nationality;

  @override
  void initState() {
    super.initState();
    _vipOnly = widget.showVipOnly;
    _nationality = widget.selectedNationality;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.filter,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _vipOnly = false;
                        _nationality = null;
                      });
                    },
                    child: Text(context.l10n.reset),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: AppSpacing.paddingScreen,
                children: [
                  SwitchListTile(
                    title: Text('VIP ${context.l10n.filter.toLowerCase()}'),
                    secondary: const Icon(Icons.star, color: AppColors.warning),
                    value: _vipOnly,
                    onChanged: (value) => setState(() => _vipOnly = value),
                  ),
                  AppSpacing.gapVerticalMd,
                  Text(
                    context.l10n.nationality,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  AppSpacing.gapVerticalSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildNationalityChip(null, context.l10n.all),
                      ...Nationalities.common.map(
                        (nat) => _buildNationalityChip(
                          nat,
                          Nationalities.getDisplayName(nat),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: context.l10n.confirm,
                    onPressed: () => widget.onApply(_vipOnly, _nationality),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNationalityChip(String? value, String label) {
    final isSelected = _nationality == value;
    return GestureDetector(
      onTap: () => setState(() => _nationality = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
