import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
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
        hintText: widget.hintText ?? 'Tìm khách theo tên, SĐT, CCCD...',
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: _searchController.text.isNotEmpty
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
            label: 'Tất cả',
            value: 'all',
            icon: Icons.search,
          ),
          AppSpacing.gapHorizontalSm,
          _buildFilterChip(
            label: 'Tên',
            value: 'name',
            icon: Icons.person_outline,
          ),
          AppSpacing.gapHorizontalSm,
          _buildFilterChip(
            label: 'SĐT',
            value: 'phone',
            icon: Icons.phone_outlined,
          ),
          AppSpacing.gapHorizontalSm,
          _buildFilterChip(
            label: 'CCCD',
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

/// Quick search field for inline guest lookup (e.g., in booking form)
class GuestQuickSearch extends StatefulWidget {
  final Function(Guest)? onGuestSelected;
  final String? hintText;

  const GuestQuickSearch({
    super.key,
    this.onGuestSelected,
    this.hintText,
  });

  @override
  State<GuestQuickSearch> createState() => _GuestQuickSearchState();
}

class _GuestQuickSearchState extends State<GuestQuickSearch> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Guest> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Nhập SĐT hoặc tên khách...',
            prefixIcon: const Icon(Icons.person_search),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _suggestions = [];
                            _showSuggestions = false;
                          });
                        },
                      )
                    : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (value.length >= 2) {
              _searchGuests(value);
            } else {
              setState(() {
                _suggestions = [];
                _showSuggestions = false;
              });
            }
          },
          onTap: () {
            if (_suggestions.isNotEmpty) {
              setState(() => _showSuggestions = true);
            }
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty) _buildSuggestionsList(),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final guest = _suggestions[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: guest.isVip
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                guest.initials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: guest.isVip ? AppColors.warning : AppColors.primary,
                ),
              ),
            ),
            title: Text(
              guest.fullName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(guest.formattedPhone),
            trailing: guest.isVip
                ? const Icon(Icons.star, size: 16, color: AppColors.warning)
                : null,
            onTap: () {
              widget.onGuestSelected?.call(guest);
              _controller.text = guest.fullName;
              setState(() => _showSuggestions = false);
              _focusNode.unfocus();
            },
          );
        },
      ),
    );
  }

  Future<void> _searchGuests(String query) async {
    setState(() => _isLoading = true);

    try {
      // This would normally call the repository directly for suggestions
      // For now, we'll simulate a delay
      await Future.delayed(const Duration(milliseconds: 300));

      // In real implementation, call repository here
      // final guests = await repository.searchGuests(query: query);

      setState(() {
        // _suggestions = guests;
        _suggestions = []; // Placeholder until integrated
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
