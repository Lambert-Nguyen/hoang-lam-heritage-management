import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/guests/guest_quick_search.dart';

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

  const BookingFormScreen({
    super.key,
    this.booking,
  });

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  int? _selectedRoomId;
  int? _selectedGuestId;
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));
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
        title: Text(isEdit ? 'Sửa đặt phòng' : 'Đặt phòng mới'),
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
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? 'Cập nhật' : 'Tạo đặt phòng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSelection() {
    // Use all rooms for now, filter available in the future
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      data: (rooms) {
        return DropdownButtonFormField<int>(
          value: _selectedRoomId,
          decoration: const InputDecoration(
            labelText: 'Phòng *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.hotel),
          ),
          items: rooms.map((room) {
            return DropdownMenuItem(
              value: room.id,
              child: Text('${room.number} - ${room.name ?? room.roomTypeName ?? ""}'),
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
            if (value == null) return 'Vui lòng chọn phòng';
            return null;
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Lỗi: $error'),
    );
  }

  Widget _buildGuestSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khách hàng *',
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
              'Vui lòng chọn hoặc tạo khách hàng',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ngày đặt phòng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Check-in date
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Check-in'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm', 'vi').format(_checkInDate)),
              onTap: () => _selectDateTime(context, true),
            ),
            
            // Check-out date
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Check-out'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm', 'vi').format(_checkOutDate)),
              onTap: () => _selectDateTime(context, false),
            ),
            
            // Nights calculation
            const Divider(),
            ListTile(
              leading: const Icon(Icons.nights_stay),
              title: const Text('Số đêm'),
              trailing: Text(
                '${_checkOutDate.difference(_checkInDate).inDays} đêm',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isCheckIn) async {
    final initialDate = isCheckIn ? _checkInDate : _checkOutDate;
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      
      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          
          if (isCheckIn) {
            _checkInDate = newDateTime;
            // Ensure check-out is after check-in
            if (_checkOutDate.isBefore(_checkInDate)) {
              _checkOutDate = _checkInDate.add(const Duration(days: 1));
            }
          } else {
            _checkOutDate = newDateTime;
          }
        });
      }
    }
  }

  Widget _buildNumberOfGuestsField() {
    return TextFormField(
      initialValue: _numberOfGuests.toString(),
      decoration: const InputDecoration(
        labelText: 'Số khách *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.people),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập số khách';
        final number = int.tryParse(value);
        if (number == null || number < 1) return 'Số khách phải >= 1';
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
      decoration: const InputDecoration(
        labelText: 'Giá/đêm (VND) *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập giá';
        final number = double.tryParse(value);
        if (number == null || number <= 0) return 'Giá phải > 0';
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
              'Tổng tiền',
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
      value: _source,
      decoration: const InputDecoration(
        labelText: 'Nguồn đặt phòng *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.source),
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
      value: _paymentMethod,
      decoration: const InputDecoration(
        labelText: 'Phương thức thanh toán *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payment),
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
      decoration: const InputDecoration(
        labelText: 'Tiền đặt cọc (VND)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.account_balance_wallet),
        helperText: 'Để trống nếu chưa đặt cọc',
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
      decoration: const InputDecoration(
        labelText: 'Yêu cầu đặc biệt',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
        helperText: 'Yêu cầu từ khách hàng',
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
      decoration: const InputDecoration(
        labelText: 'Ghi chú nội bộ',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
        helperText: 'Ghi chú cho nhân viên',
      ),
      maxLines: 3,
      onChanged: (value) {
        _internalNotes = value;
      },
    );
  }

  String _getBookingSourceLabel(BookingSource source) {
    switch (source) {
      case BookingSource.walkIn:
        return 'Walk-in (Khách vãng lai)';
      case BookingSource.phone:
        return 'Điện thoại';
      case BookingSource.bookingCom:
        return 'Booking.com';
      case BookingSource.agoda:
        return 'Agoda';
      case BookingSource.airbnb:
        return 'Airbnb';
      case BookingSource.traveloka:
        return 'Traveloka';
      case BookingSource.otherOta:
        return 'OTA khác';
      case BookingSource.website:
        return 'Website';
      case BookingSource.other:
        return 'Khác';
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.card:
        return 'Thẻ tín dụng';
      case PaymentMethod.otaCollect:
        return 'OTA thu hộ';
      case PaymentMethod.other:
        return 'Khác';
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng')),
      );
      return;
    }

    if (_selectedGuestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng')),
      );
      return;
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

        await ref.read(bookingNotifierProvider.notifier).createBooking(bookingCreate);
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

        await ref.read(bookingNotifierProvider.notifier).updateBooking(
              widget.booking!.id,
              bookingUpdate,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.booking == null
                  ? 'Đã tạo đặt phòng thành công'
                  : 'Đã cập nhật đặt phòng',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
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
