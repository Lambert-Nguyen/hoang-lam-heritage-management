import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';
import '../../screens/guests/guest_form_screen.dart';

/// Guest Quick Search Widget
/// 
/// Provides inline guest selection with:
/// - Search autocomplete
/// - Quick guest creation
/// - Selected guest display
class GuestQuickSearch extends ConsumerStatefulWidget {
  final Function(Guest) onGuestSelected;
  final int? initialGuestId;

  const GuestQuickSearch({
    super.key,
    required this.onGuestSelected,
    this.initialGuestId,
  });

  @override
  ConsumerState<GuestQuickSearch> createState() => _GuestQuickSearchState();
}

class _GuestQuickSearchState extends ConsumerState<GuestQuickSearch> {
  int? _selectedGuestId;
  Guest? _selectedGuest;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Guest> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedGuestId = widget.initialGuestId;
    if (_selectedGuestId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialGuest();
      });
    }
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 2) {
      _removeOverlay();
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final repository = ref.read(guestRepositoryProvider);
      final results = await repository.searchGuests(query: query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      _showOverlay();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (_searchResults.isEmpty && !_isSearching) {
      // Show "no results" overlay
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      return;
    }
    if (_searchResults.isNotEmpty) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _searchResults.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Không tìm thấy khách hàng'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final guest = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(guest.initials),
                          ),
                          title: Text(guest.fullName),
                          subtitle: Text(guest.phone),
                          onTap: () {
                            _removeOverlay();
                            _searchController.clear();
                            setState(() {
                              _selectedGuest = guest;
                              _selectedGuestId = guest.id;
                            });
                            widget.onGuestSelected(guest);
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadInitialGuest() async {
    if (_selectedGuestId == null) return;
    try {
      final guest = await ref.read(guestByIdProvider(_selectedGuestId!).future);
      setState(() {
        _selectedGuest = guest;
      });
    } catch (e) {
      // Guest not found, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedGuest != null) {
      return _buildSelectedGuest();
    }

    return _buildSearchField();
  }

  Widget _buildSelectedGuest() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(_selectedGuest!.initials),
        ),
        title: Text(_selectedGuest!.fullName),
        subtitle: Text(_selectedGuest!.phone),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _selectedGuest = null;
              _selectedGuestId = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: 'Tìm khách hàng',
              hintText: 'Nhập ít nhất 2 ký tự',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _removeOverlay();
                          },
                        )
                      : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              _removeOverlay();
              final result = await Navigator.of(context).push<Guest>(
                MaterialPageRoute(
                  builder: (context) => const GuestFormScreen(),
                  fullscreenDialog: true,
                ),
              );
              if (result != null) {
                setState(() {
                  _selectedGuest = result;
                  _selectedGuestId = result.id;
                });
                widget.onGuestSelected(result);
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Tạo khách hàng mới'),
          ),
        ],
      ),
    );
  }
}
