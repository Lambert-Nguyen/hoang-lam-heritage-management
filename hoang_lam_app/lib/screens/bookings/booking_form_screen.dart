import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/guests/guest_quick_search.dart';
import '../../core/theme/app_colors.dart';

/// Booking Form Screen - Phase 1.9.6
///
/// Form for creating new bookings or editing existing ones:
/// - Room selection
/// - Guest selection/creation
/// - Date and time selection
/// - Rate input
/// - Payment method and deposit
/// - Booking source
/// - Special requests and notes
///
/// Validation:
/// - Required fields
/// - Date logic (check-out after check-in)
/// - Room availability
class BookingFormScreen extends ConsumerStatefulWidget {
  final Booking? booking; // null for new booking, provided for edit

  const BookingFormScreen({super.key, this.booking});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  int? _selectedRoomId;
  int? _selectedGuestId;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  double _ratePerNight = 0;
  int _numberOfGuests = 1;
  BookingSource _source = BookingSource.walkIn;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  double _depositAmount = 0;
  String _specialRequests = '';
  String _internalNotes = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _checkInDate = DateTime(now.year, now.month, now.day);
    _checkOutDate = DateTime(now.year, now.month, now.day + 1);
    if (widget.booking != null) {
      _initializeFromBooking(widget.booking!);
    }
  }

  void _initializeFromBooking(Booking booking) {
    _selectedRoomId = booking.room;
    _selectedGuestId = booking.guest;
    _checkInDate = booking.checkInDate;
    _checkOutDate = booking.checkOutDate;
    _ratePerNight = booking.nightlyRate.toDouble();
    _numberOfGuests = booking.guestCount;
    _source = booking.source;
    _paymentMethod = booking.paymentMethod;
    _depositAmount = booking.depositAmount.toDouble();
    _specialRequests = booking.specialRequests;
    _internalNotes = booking.notes;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.booking != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? context.l10n.editBooking : context.l10n.createBooking,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Room Selection
            _buildRoomSelection(),
            const SizedBox(height: 16),

            // Guest Selection
            _buildGuestSelection(),
            const SizedBox(height: 16),

            // Dates
            _buildDateSection(),
            const SizedBox(height: 16),

            // Number of Guests
            _buildNumberOfGuestsField(),
            const SizedBox(height: 16),

            // Rate per night
            _buildRateField(),
            const SizedBox(height: 16),

            // Total amount (calculated)
            _buildTotalDisplay(),
            const SizedBox(height: 16),

            // Optional fields — collapsed by default for quick walk-in bookings
            ExpansionTile(
              title: Text(context.l10n.optionalFields),
              leading: const Icon(Icons.tune),
              initiallyExpanded: isEdit,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                // Booking Source
                _buildSourceSelection(),
                const SizedBox(height: 16),

                // Payment Method
                _buildPaymentMethodSelection(),
                const SizedBox(height: 16),

                // Deposit
                _buildDepositField(),
                const SizedBox(height: 16),

                // Special Requests
                _buildSpecialRequestsField(),
                const SizedBox(height: 16),

                // Internal Notes
                _buildInternalNotesField(),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : Text(
                      isEdit ? context.l10n.update : context.l10n.createBooking,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSelection() {
    // Use availableRoomsProvider to filter by date range when dates are set
    final filter = AvailabilityFilter(
      checkIn: _checkInDate,
      checkOut: _checkOutDate,
    );
    final availableAsync = ref.watch(availableRoomsProvider(filter));
    // Fallback to all rooms if availability check fails
    final roomsAsync = ref.watch(roomsProvider);

    return availableAsync.when(
      data: (availableRooms) {
        // When editing, ensure the currently selected room is always in the list
        final rooms = widget.booking != null
            ? (() {
                final allRooms = roomsAsync.valueOrNull ?? availableRooms;
                final ids = availableRooms.map((r) => r.id).toSet();
                return [
                  ...availableRooms,
                  ...allRooms.where(
                    (r) => r.id == _selectedRoomId && !ids.contains(r.id),
                  ),
                ];
              })()
            : availableRooms;

        return DropdownButtonFormField<int>(
          initialValue: _selectedRoomId,
          decoration: InputDecoration(
            labelText: '${context.l10n.roomNumber} *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.hotel),
            helperText: '${rooms.length} ${context.l10n.availableRooms}',
          ),
          items: rooms.map((room) {
            final isAvailable = availableRooms.any((r) => r.id == room.id);
            return DropdownMenuItem(
              value: room.id,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${room.number} - ${room.name ?? room.roomTypeName ?? ""}',
                    ),
                  ),
                  if (!isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.occupied.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.occupied,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.occupied,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRoomId = value;
              // Auto-fill rate if room has baseRate
              if (value != null) {
                final room = rooms.firstWhere((r) => r.id == value);
                if (room.baseRate != null && _ratePerNight == 0) {
                  _ratePerNight = room.baseRate!.toDouble();
                }
              }
            });
          },
          validator: (value) {
            if (value == null) return context.l10n.pleaseSelectRoom;
            return null;
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('${context.l10n.error}: $error'),
    );
  }

  Widget _buildGuestSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.l10n.guest} *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        GuestQuickSearch(
          onGuestSelected: (guest) {
            setState(() {
              _selectedGuestId = guest.id;
            });
          },
          initialGuestId: _selectedGuestId,
        ),
        if (_selectedGuestId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.pleaseSelectCreateGuest,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSection() {
    final theme = Theme.of(context);
    final nights = _checkOutDate.difference(_checkInDate).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.bookingDates,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Check-in / Check-out date row
            Row(
              children: [
                // Check-in
                Expanded(
                  child: _buildDateCard(
                    icon: Icons.login,
                    label: context.l10n.checkIn,
                    date: _checkInDate,
                    onTap: () => _selectDate(context, true),
                    color: theme.colorScheme.primary,
                  ),
                ),

                // Arrow and nights badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$nights ${context.l10n.nights}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Check-out
                Expanded(
                  child: _buildDateCard(
                    icon: Icons.logout,
                    label: context.l10n.checkOut,
                    date: _checkOutDate,
                    onTap: () => _selectDate(context, false),
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required IconData icon,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(80)),
          borderRadius: BorderRadius.circular(12),
          color: color.withAlpha(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd', 'vi').format(date),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              DateFormat('MMM yyyy', 'vi').format(date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              DateFormat('EEEE', 'vi').format(date),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final initialDate = isCheckIn ? _checkInDate : _checkOutDate;
    final firstDate = isCheckIn
        ? DateTime.now().subtract(const Duration(days: 30))
        : _checkInDate.add(const Duration(days: 1));
    final adjustedInitialDate = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate;

    final date = await showDatePicker(
      context: context,
      initialDate: adjustedInitialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isCheckIn ? context.l10n.checkIn : context.l10n.checkOut,
    );

    if (date != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = date;
          // Ensure check-out is after check-in
          if (!_checkOutDate.isAfter(_checkInDate)) {
            _checkOutDate = _checkInDate.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = date;
        }
      });
    }
  }

  Widget _buildNumberOfGuestsField() {
    return TextFormField(
      initialValue: _numberOfGuests.toString(),
      decoration: InputDecoration(
        labelText: '${context.l10n.guestCount} *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.people),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return context.l10n.guestRequired;
        final number = int.tryParse(value);
        if (number == null || number < 1) return context.l10n.guestRequired;
        return null;
      },
      onChanged: (value) {
        final number = int.tryParse(value);
        if (number != null) {
          setState(() {
            _numberOfGuests = number;
          });
        }
      },
    );
  }

  Widget _buildRateField() {
    return TextFormField(
      initialValue: _ratePerNight > 0 ? _ratePerNight.toStringAsFixed(0) : '',
      decoration: InputDecoration(
        labelText: '${context.l10n.ratePerNight} (VND) *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return context.l10n.pleaseEnterRate;
        final number = double.tryParse(value);
        if (number == null || number <= 0) {
          return context.l10n.rateMustBePositive;
        }
        return null;
      },
      onChanged: (value) {
        final number = double.tryParse(value);
        if (number != null) {
          setState(() {
            _ratePerNight = number;
          });
        }
      },
    );
  }

  Widget _buildTotalDisplay() {
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    final total = _ratePerNight * nights;
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.totalAmount,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              currencyFormat.format(total),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSelection() {
    return DropdownButtonFormField<BookingSource>(
      initialValue: _source,
      decoration: InputDecoration(
        labelText: '${context.l10n.source} *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.source),
      ),
      items: BookingSource.values.map((source) {
        return DropdownMenuItem(
          value: source,
          child: Text(_getBookingSourceLabel(source)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _source = value;
          });
        }
      },
    );
  }

  Widget _buildPaymentMethodSelection() {
    return DropdownButtonFormField<PaymentMethod>(
      initialValue: _paymentMethod,
      decoration: InputDecoration(
        labelText: '${context.l10n.paymentMethod} *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.payment),
      ),
      items: PaymentMethod.values.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(_getPaymentMethodLabel(method)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _paymentMethod = value;
          });
        }
      },
    );
  }

  Widget _buildDepositField() {
    return TextFormField(
      initialValue: _depositAmount > 0 ? _depositAmount.toStringAsFixed(0) : '',
      decoration: InputDecoration(
        labelText: '${context.l10n.deposit} (VND)',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.account_balance_wallet),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final number = double.tryParse(value);
        setState(() {
          _depositAmount = number ?? 0;
        });
      },
    );
  }

  Widget _buildSpecialRequestsField() {
    return TextFormField(
      initialValue: _specialRequests,
      decoration: InputDecoration(
        labelText: context.l10n.specialRequests,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.note),
      ),
      maxLines: 3,
      onChanged: (value) {
        _specialRequests = value;
      },
    );
  }

  Widget _buildInternalNotesField() {
    return TextFormField(
      initialValue: _internalNotes,
      decoration: InputDecoration(
        labelText: context.l10n.internalNotes,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.notes),
      ),
      maxLines: 3,
      onChanged: (value) {
        _internalNotes = value;
      },
    );
  }

  String _getBookingSourceLabel(BookingSource source) {
    final l10n = context.l10n;
    switch (source) {
      case BookingSource.walkIn:
        return l10n.bookingSourceWalkIn;
      case BookingSource.phone:
        return l10n.bookingSourcePhone;
      case BookingSource.bookingCom:
        return l10n.bookingSourceBookingCom;
      case BookingSource.agoda:
        return l10n.bookingSourceAgoda;
      case BookingSource.airbnb:
        return l10n.bookingSourceAirbnb;
      case BookingSource.traveloka:
        return l10n.bookingSourceTraveloka;
      case BookingSource.otherOta:
        return l10n.bookingSourceOtherOta;
      case BookingSource.website:
        return l10n.bookingSourceWebsite;
      case BookingSource.other:
        return l10n.bookingSourceOther;
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    final l10n = context.l10n;
    switch (method) {
      case PaymentMethod.cash:
        return l10n.paymentMethodCash;
      case PaymentMethod.bankTransfer:
        return l10n.paymentMethodBankTransfer;
      case PaymentMethod.momo:
        return l10n.paymentMethodMomo;
      case PaymentMethod.vnpay:
        return l10n.paymentMethodVnpay;
      case PaymentMethod.card:
        return l10n.paymentMethodCard;
      case PaymentMethod.otaCollect:
        return l10n.paymentMethodOtaCollect;
      case PaymentMethod.other:
        return l10n.paymentMethodOther;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.pleaseSelectRoom)));
      return;
    }

    if (_selectedGuestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectCreateGuest)),
      );
      return;
    }

    if (!_checkOutDate.isAfter(_checkInDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.checkOut} must be after ${context.l10n.checkIn}',
          ),
        ),
      );
      return;
    }

    // TODO: Replace with a proper server-side availability check using
    // availableRoomsProvider once the backend endpoint is fully integrated.
    // For now, warn if the selected room has overlapping bookings.
    if (_selectedRoomId != null && widget.booking == null) {
      try {
        final existingBookings = await ref.read(
          bookingsByRoomProvider(
            BookingsByRoomParams(
              roomId: _selectedRoomId!,
              from: _checkInDate,
              to: _checkOutDate,
            ),
          ).future,
        );
        final overlapping = existingBookings
            .where(
              (b) =>
                  b.status != BookingStatus.cancelled &&
                  b.status != BookingStatus.noShow &&
                  b.checkInDate.isBefore(_checkOutDate) &&
                  b.checkOutDate.isAfter(_checkInDate),
            )
            .toList();

        if (overlapping.isNotEmpty && mounted) {
          final l10n = context.l10n;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.overlapWarningTitle),
              content: Text(
                l10n.overlapWarningMessage.replaceAll(
                  '{count}',
                  overlapping.length.toString(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(context.l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(context.l10n.confirm),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }
      } catch (_) {
        // If availability check fails, allow the booking to proceed
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.booking == null) {
        // Create new booking
        final bookingCreate = BookingCreate(
          room: _selectedRoomId!,
          guest: _selectedGuestId!,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          guestCount: _numberOfGuests,
          nightlyRate: _ratePerNight.toInt(),
          source: _source,
          paymentMethod: _paymentMethod,
          depositAmount: _depositAmount.toInt(),
          specialRequests: _specialRequests.isEmpty ? '' : _specialRequests,
          notes: _internalNotes.isEmpty ? '' : _internalNotes,
        );

        await ref
            .read(bookingNotifierProvider.notifier)
            .createBooking(bookingCreate);
      } else {
        // Update existing booking
        final bookingUpdate = BookingUpdate(
          room: _selectedRoomId,
          guest: _selectedGuestId,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          guestCount: _numberOfGuests,
          nightlyRate: _ratePerNight.toInt(),
          source: _source,
          paymentMethod: _paymentMethod,
          depositAmount: _depositAmount.toInt(),
          specialRequests: _specialRequests.isEmpty ? '' : _specialRequests,
          notes: _internalNotes.isEmpty ? '' : _internalNotes,
        );

        await ref
            .read(bookingNotifierProvider.notifier)
            .updateBooking(widget.booking!.id, bookingUpdate);
      }

      // Invalidate booking providers so lists/calendars refresh
      ref.invalidate(bookingsProvider);
      ref.invalidate(activeBookingsProvider);
      ref.invalidate(calendarBookingsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.booking == null
                  ? context.l10n.success
                  : context.l10n.success,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
