import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';

/// Search bar widget for finding guests
class GuestSearchBar extends ConsumerStatefulWidget {
  final Function(List<Guest>)? onSearchResults;
  final Function(String)? onQueryChanged;
  final String? hintText;
  final bool showFilters;

  const GuestSearchBar({
    super.key,
    this.onSearchResults,
    this.onQueryChanged,
    this.hintText,
    this.showFilters = true,
  });

  @override
  ConsumerState<GuestSearchBar> createState() => _GuestSearchBarState();
}

class _GuestSearchBarState extends ConsumerState<GuestSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'all';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        if (widget.showFilters) ...[
          AppSpacing.gapVerticalSm,
          _buildFilterChips(),
        ],
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: widget.hintText ?? context.l10n.searchGuestHint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: _clearSearch,
                )
                : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      onChanged: (value) {
        setState(() {});
        widget.onQueryChanged?.call(value);
        if (value.length >= 2) {
          _performSearch(value);
        }
      },
      onSubmitted: (value) {
        if (value.length >= 2) {
          _performSearch(value);
        }
      },
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: context.l10n.all,
            value: 'all',
            icon: Icons.search,
          ),
          AppSpacing.gapHorizontalSm,
          _buildFilterChip(
            label: context.l10n.name,
            value: 'name',
            icon: Icons.person_outline,
          ),
          AppSpacing.gapHorizontalSm,
          _buildFilterChip(
            label: context.l10n.phoneLabel,
            value: 'phone',
            icon: Icons.phone_outlined,
          ),
          AppSpacing.gapHorizontalSm,
          _buildFilterChip(
            label: context.l10n.idNumber,
            value: 'id_number',
            icon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _searchType == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
          AppSpacing.gapHorizontalXs,
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _searchType = selected ? value : 'all';
        });
        if (_searchController.text.length >= 2) {
          _performSearch(_searchController.text);
        }
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
        fontSize: 13,
      ),
      checkmarkColor: AppColors.onPrimary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    widget.onQueryChanged?.call('');
    widget.onSearchResults?.call([]);
  }

  Future<void> _performSearch(String query) async {
    if (_isSearching) return;

    setState(() => _isSearching = true);

    try {
      final notifier = ref.read(guestStateProvider.notifier);
      await notifier.searchGuests(query, searchBy: _searchType);

      final state = ref.read(guestStateProvider);
      state.maybeWhen(
        loaded: (guests) => widget.onSearchResults?.call(guests),
        orElse: () {},
      );
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }
}
