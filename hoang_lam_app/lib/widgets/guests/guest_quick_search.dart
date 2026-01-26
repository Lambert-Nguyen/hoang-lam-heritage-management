import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';

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
  final TextEditingController _searchController = TextEditingController();
  int? _selectedGuestId;
  Guest? _selectedGuest;

  @override
  void initState() {
    super.initState();
    _selectedGuestId = widget.initialGuestId;
    if (_selectedGuestId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialGuest();
      });
    }
  }

  Future<void> _loadInitialGuest() async {
    if (_selectedGuestId == null) return;
    try {
      final guest = await ref.read(guestByIdProvider(_selectedGuestId!).future);
      setState(() {
        _selectedGuest = guest;
        _searchController.text = guest.fullName;
      });
    } catch (e) {
      // Guest not found, ignore
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              _searchController.clear();
            });
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Column(
      children: [
        Autocomplete<Guest>(
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Guest>.empty();
            }

            try {
              final guests = await ref.read(
                guestSearchProvider(GuestSearchParams(
                  query: textEditingValue.text,
                )).future,
              );
              return guests;
            } catch (e) {
              return const Iterable<Guest>.empty();
            }
          },
          displayStringForOption: (guest) => guest.fullName,
          onSelected: (guest) {
            setState(() {
              _selectedGuest = guest;
              _selectedGuestId = guest.id;
              _searchController.text = guest.fullName;
            });
            widget.onGuestSelected(guest);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _searchController.text = controller.text;
            _searchController.selection = controller.selection;

            return TextField(
              controller: _searchController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Tìm khách hàng',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          controller.clear();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                controller.text = value;
                controller.selection = _searchController.selection;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  width: MediaQuery.of(context).size.width - 32,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final guest = options.elementAt(index);
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(guest.initials),
                        ),
                        title: Text(guest.fullName),
                        subtitle: Text(guest.phone),
                        onTap: () {
                          onSelected(guest);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            // TODO: Navigate to guest form screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tạo khách hàng mới - đang phát triển'),
              ),
            );
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Tạo khách hàng mới'),
        ),
      ],
    );
  }
}
