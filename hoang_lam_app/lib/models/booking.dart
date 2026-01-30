import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

/// Booking status matching backend Booking.Status choices
enum BookingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('checked_in')
  checkedIn,
  @JsonValue('checked_out')
  checkedOut,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('no_show')
  noShow,
}

/// Extension for BookingStatus display properties
extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.checkedIn:
        return 'Đang ở';
      case BookingStatus.checkedOut:
        return 'Đã trả phòng';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.noShow:
        return 'Không đến';
    }
  }

  String get displayNameEn {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case BookingStatus.confirmed:
        return const Color(0xFF42A5F5); // Blue
      case BookingStatus.checkedIn:
        return const Color(0xFF4CAF50); // Green
      case BookingStatus.checkedOut:
        return const Color(0xFF9E9E9E); // Grey
      case BookingStatus.cancelled:
        return const Color(0xFFF44336); // Red
      case BookingStatus.noShow:
        return const Color(0xFF795548); // Brown
    }
  }

  Color get backgroundColor {
    switch (this) {
      case BookingStatus.pending:
        return const Color(0xFFFFF3E0); // Orange light
      case BookingStatus.confirmed:
        return const Color(0xFFE3F2FD); // Blue light
      case BookingStatus.checkedIn:
        return const Color(0xFFE8F5E9); // Green light
      case BookingStatus.checkedOut:
        return const Color(0xFFF5F5F5); // Grey light
      case BookingStatus.cancelled:
        return const Color(0xFFFFEBEE); // Red light
      case BookingStatus.noShow:
        return const Color(0xFFEFEBE9); // Brown light
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.checkedIn:
        return Icons.login;
      case BookingStatus.checkedOut:
        return Icons.logout;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
      case BookingStatus.noShow:
        return Icons.person_off_outlined;
    }
  }

  /// Whether this status allows check-in
  bool get canCheckIn =>
      this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// Whether this status allows check-out
  bool get canCheckOut => this == BookingStatus.checkedIn;

  /// Whether this booking can be cancelled
  bool get canCancel =>
      this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// Whether this booking can be edited
  bool get canEdit =>
      this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// Whether this is an active booking
  bool get isActive =>
      this == BookingStatus.confirmed || this == BookingStatus.checkedIn;

  /// Whether this booking is completed
  bool get isCompleted =>
      this == BookingStatus.checkedOut ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.noShow;

  /// Get the snake_case API value for this status
  String get toApiValue {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.checkedIn:
        return 'checked_in';
      case BookingStatus.checkedOut:
        return 'checked_out';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.noShow:
        return 'no_show';
    }
  }
}

/// Booking source matching backend Booking.Source choices
enum BookingSource {
  @JsonValue('walk_in')
  walkIn,
  @JsonValue('phone')
  phone,
  @JsonValue('website')
  website,
  @JsonValue('booking_com')
  bookingCom,
  @JsonValue('agoda')
  agoda,
  @JsonValue('airbnb')
  airbnb,
  @JsonValue('traveloka')
  traveloka,
  @JsonValue('other_ota')
  otherOta,
  @JsonValue('other')
  other,
}

/// Extension for BookingSource display properties
extension BookingSourceExtension on BookingSource {
  String get displayName {
    switch (this) {
      case BookingSource.walkIn:
        return 'Khách vãng lai';
      case BookingSource.phone:
        return 'Điện thoại';
      case BookingSource.website:
        return 'Website';
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
      case BookingSource.other:
        return 'Khác';
    }
  }

  String get displayNameEn {
    switch (this) {
      case BookingSource.walkIn:
        return 'Walk-in';
      case BookingSource.phone:
        return 'Phone';
      case BookingSource.website:
        return 'Website';
      case BookingSource.bookingCom:
        return 'Booking.com';
      case BookingSource.agoda:
        return 'Agoda';
      case BookingSource.airbnb:
        return 'Airbnb';
      case BookingSource.traveloka:
        return 'Traveloka';
      case BookingSource.otherOta:
        return 'Other OTA';
      case BookingSource.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case BookingSource.walkIn:
        return Icons.directions_walk;
      case BookingSource.phone:
        return Icons.phone;
      case BookingSource.website:
        return Icons.language;
      case BookingSource.bookingCom:
        return Icons.travel_explore;
      case BookingSource.agoda:
        return Icons.travel_explore;
      case BookingSource.airbnb:
        return Icons.house;
      case BookingSource.traveloka:
        return Icons.flight;
      case BookingSource.otherOta:
        return Icons.public;
      case BookingSource.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case BookingSource.walkIn:
        return const Color(0xFF4CAF50); // Green
      case BookingSource.phone:
        return const Color(0xFF2196F3); // Blue
      case BookingSource.website:
        return const Color(0xFF9C27B0); // Purple
      case BookingSource.bookingCom:
        return const Color(0xFF003580); // Booking.com blue
      case BookingSource.agoda:
        return const Color(0xFFE52E2E); // Agoda red
      case BookingSource.airbnb:
        return const Color(0xFFFF5A5F); // Airbnb red
      case BookingSource.traveloka:
        return const Color(0xFF0194F3); // Traveloka blue
      case BookingSource.otherOta:
        return const Color(0xFF607D8B); // Blue grey
      case BookingSource.other:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Whether this source is from an OTA
  bool get isOta => [
        BookingSource.bookingCom,
        BookingSource.agoda,
        BookingSource.airbnb,
        BookingSource.traveloka,
        BookingSource.otherOta,
      ].contains(this);

  /// Whether this source is direct booking
  bool get isDirect => [
        BookingSource.walkIn,
        BookingSource.phone,
        BookingSource.website,
      ].contains(this);
}

/// Payment method matching backend Booking.PaymentMethod choices
enum PaymentMethod {
  @JsonValue('cash')
  cash,
  @JsonValue('bank_transfer')
  bankTransfer,
  @JsonValue('momo')
  momo,
  @JsonValue('vnpay')
  vnpay,
  @JsonValue('card')
  card,
  @JsonValue('ota_collect')
  otaCollect,
  @JsonValue('other')
  other,
}

/// Extension for PaymentMethod display properties
extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.card:
        return 'Thẻ';
      case PaymentMethod.otaCollect:
        return 'OTA thu hộ';
      case PaymentMethod.other:
        return 'Khác';
    }
  }

  String get displayNameEn {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.otaCollect:
        return 'OTA Collect';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.momo:
        return Icons.phone_android;
      case PaymentMethod.vnpay:
        return Icons.qr_code;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.otaCollect:
        return Icons.travel_explore;
      case PaymentMethod.other:
        return Icons.payment;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return const Color(0xFF4CAF50); // Green
      case PaymentMethod.bankTransfer:
        return const Color(0xFF2196F3); // Blue
      case PaymentMethod.momo:
        return const Color(0xFFD82D8B); // MoMo pink
      case PaymentMethod.vnpay:
        return const Color(0xFF1A1F71); // VNPay blue
      case PaymentMethod.card:
        return const Color(0xFF9C27B0); // Purple
      case PaymentMethod.otaCollect:
        return const Color(0xFF607D8B); // Blue grey
      case PaymentMethod.other:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}

/// Lightweight guest summary for booking display
@freezed
sealed class GuestSummary with _$GuestSummary {
  const factory GuestSummary({
    required int id,
    @JsonKey(name: 'full_name') required String fullName,
    @Default('') String phone,
    String? email,
    String? nationality,
    @JsonKey(name: 'is_vip') @Default(false) bool isVip,
  }) = _GuestSummary;

  const GuestSummary._();

  factory GuestSummary.fromJson(Map<String, dynamic> json) =>
      _$GuestSummaryFromJson(json);

  /// Get initials for avatar
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Booking model matching backend BookingSerializer
@freezed
sealed class Booking with _$Booking {
  const factory Booking({
    required int id,

    // Room reference
    required int room,
    @JsonKey(name: 'room_number') String? roomNumber,
    @JsonKey(name: 'room_type_name') String? roomTypeName,

    // Dates
    @JsonKey(name: 'check_in_date') required DateTime checkInDate,
    @JsonKey(name: 'check_out_date') required DateTime checkOutDate,
    @JsonKey(name: 'actual_check_in') DateTime? actualCheckIn,
    @JsonKey(name: 'actual_check_out') DateTime? actualCheckOut,

    // Guest
    required int guest,
    @JsonKey(name: 'guest_details') GuestSummary? guestDetails,
    @JsonKey(name: 'guest_count') @Default(1) int guestCount,

    // Status
    @Default(BookingStatus.confirmed) BookingStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @Default(BookingSource.walkIn) BookingSource source,
    @JsonKey(name: 'source_display') String? sourceDisplay,
    @JsonKey(name: 'ota_reference') @Default('') String otaReference,

    // Pricing
    @JsonKey(name: 'nightly_rate') required int nightlyRate,
    @JsonKey(name: 'total_amount') required int totalAmount,
    @Default('VND') String currency,

    // Payment
    @JsonKey(name: 'deposit_amount') @Default(0) int depositAmount,
    @JsonKey(name: 'deposit_paid') @Default(false) bool depositPaid,
    @JsonKey(name: 'additional_charges') @Default(0) int additionalCharges,
    @JsonKey(name: 'payment_method') @Default(PaymentMethod.cash) PaymentMethod paymentMethod,
    @JsonKey(name: 'is_paid') @Default(false) bool isPaid,

    // Notes
    @Default('') String notes,
    @JsonKey(name: 'special_requests') @Default('') String specialRequests,

    // Computed from backend
    int? nights,
    @JsonKey(name: 'balance_due') int? balanceDue,

    // Audit
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Booking;

  const Booking._();

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);

  /// Create a new booking for the form
  factory Booking.create({
    required int roomId,
    required int guestId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int nightlyRate,
    int guestCount = 1,
    BookingStatus status = BookingStatus.confirmed,
    BookingSource source = BookingSource.walkIn,
    String otaReference = '',
    int depositAmount = 0,
    bool depositPaid = false,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String notes = '',
    String specialRequests = '',
  }) {
    final nights = checkOutDate.difference(checkInDate).inDays;
    return Booking(
      id: 0, // Will be assigned by backend
      room: roomId,
      guest: guestId,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      guestCount: guestCount,
      status: status,
      source: source,
      otaReference: otaReference,
      nightlyRate: nightlyRate,
      totalAmount: nightlyRate * nights,
      depositAmount: depositAmount,
      depositPaid: depositPaid,
      paymentMethod: paymentMethod,
      notes: notes,
      specialRequests: specialRequests,
    );
  }

  /// Calculate nights from dates
  int get calculatedNights => checkOutDate.difference(checkInDate).inDays;

  /// Calculate balance due
  int get calculatedBalanceDue => totalAmount + additionalCharges - depositAmount;

  /// Get guest name (from details or fallback)
  String get guestName => guestDetails?.fullName ?? 'Khách #$guest';

  /// Get guest phone (from details or empty)
  String get guestPhone => guestDetails?.phone ?? '';

  /// Check if booking is for today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkIn = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
    final checkOut = DateTime(checkOutDate.year, checkOutDate.month, checkOutDate.day);
    return today.isAtSameMomentAs(checkIn) ||
        (today.isAfter(checkIn) && today.isBefore(checkOut));
  }

  /// Check if check-in is due today
  bool get checkInDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkIn = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
    return checkIn.isAtSameMomentAs(today) && status.canCheckIn;
  }

  /// Check if check-out is due today
  bool get checkOutDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkOut = DateTime(checkOutDate.year, checkOutDate.month, checkOutDate.day);
    return checkOut.isAtSameMomentAs(today) && status == BookingStatus.checkedIn;
  }

  /// Check if booking overlaps with a date range
  bool overlapsWithRange(DateTime start, DateTime end) {
    return checkInDate.isBefore(end) && checkOutDate.isAfter(start);
  }

  /// Get formatted date range (e.g., "19/01 - 21/01")
  String get dateRangeDisplay {
    final inDay = checkInDate.day.toString().padLeft(2, '0');
    final inMonth = checkInDate.month.toString().padLeft(2, '0');
    final outDay = checkOutDate.day.toString().padLeft(2, '0');
    final outMonth = checkOutDate.month.toString().padLeft(2, '0');
    return '$inDay/$inMonth - $outDay/$outMonth';
  }

  /// Get formatted date range with year
  String get fullDateRangeDisplay {
    final inDay = checkInDate.day.toString().padLeft(2, '0');
    final inMonth = checkInDate.month.toString().padLeft(2, '0');
    final inYear = checkInDate.year;
    final outDay = checkOutDate.day.toString().padLeft(2, '0');
    final outMonth = checkOutDate.month.toString().padLeft(2, '0');
    final outYear = checkOutDate.year;

    if (inYear == outYear) {
      return '$inDay/$inMonth - $outDay/$outMonth/$outYear';
    }
    return '$inDay/$inMonth/$inYear - $outDay/$outMonth/$outYear';
  }

  /// Get formatted total amount
  String get formattedTotal {
    final formatted = totalAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted $currency';
  }

  /// Get formatted nightly rate
  String get formattedNightlyRate {
    final formatted = nightlyRate.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted $currency';
  }

  /// Get formatted balance due
  String get formattedBalanceDue {
    final balance = calculatedBalanceDue;
    final formatted = balance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted $currency';
  }

  /// Whether booking has outstanding balance
  bool get hasBalance => calculatedBalanceDue > 0;

  /// Whether booking is from OTA
  bool get isOtaBooking => source.isOta;
}

/// Booking list response matching paginated API response
@freezed
sealed class BookingListResponse with _$BookingListResponse {
  const factory BookingListResponse({
    required int count,
    String? next,
    String? previous,
    required List<Booking> results,
  }) = _BookingListResponse;

  factory BookingListResponse.fromJson(Map<String, dynamic> json) =>
      _$BookingListResponseFromJson(json);
}

/// Calendar booking response
@freezed
sealed class CalendarResponse with _$CalendarResponse {
  const factory CalendarResponse({
    required List<Booking> bookings,
    required int total,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
  }) = _CalendarResponse;

  factory CalendarResponse.fromJson(Map<String, dynamic> json) =>
      _$CalendarResponseFromJson(json);
}

/// Today's bookings response
@freezed
sealed class TodayBookingsResponse with _$TodayBookingsResponse {
  const factory TodayBookingsResponse({
    @JsonKey(name: 'check_ins') required List<Booking> checkIns,
    @JsonKey(name: 'check_outs') required List<Booking> checkOuts,
    @JsonKey(name: 'total_check_ins') required int totalCheckIns,
    @JsonKey(name: 'total_check_outs') required int totalCheckOuts,
  }) = _TodayBookingsResponse;

  factory TodayBookingsResponse.fromJson(Map<String, dynamic> json) =>
      _$TodayBookingsResponseFromJson(json);
}

/// Booking filter parameters
@freezed
sealed class BookingFilter with _$BookingFilter {
  const factory BookingFilter({
    DateTime? startDate,
    DateTime? endDate,
    BookingStatus? status,
    BookingSource? source,
    int? roomId,
    int? guestId,
    bool? isPaid,
    @Default('-created_at') String ordering,
  }) = _BookingFilter;

  const BookingFilter._();

  /// Check if any filter is active
  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      status != null ||
      source != null ||
      roomId != null ||
      guestId != null ||
      isPaid != null;

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (startDate != null) count++;
    if (endDate != null) count++;
    if (status != null) count++;
    if (source != null) count++;
    if (roomId != null) count++;
    if (guestId != null) count++;
    if (isPaid != null) count++;
    return count;
  }
}

/// Date range for calendar queries
@freezed
sealed class DateRange with _$DateRange {
  const factory DateRange({
    required DateTime start,
    required DateTime end,
  }) = _DateRange;

  const DateRange._();

  /// Get number of days in range
  int get days => end.difference(start).inDays;

  /// Check if a date is within the range
  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }
}

/// Model for creating a new booking
@freezed
sealed class BookingCreate with _$BookingCreate {
  const factory BookingCreate({
    required int room,
    required int guest,
    @JsonKey(name: 'check_in_date') required DateTime checkInDate,
    @JsonKey(name: 'check_out_date') required DateTime checkOutDate,
    @JsonKey(name: 'guest_count') @Default(1) int guestCount,
    @Default(BookingStatus.confirmed) BookingStatus status,
    @Default(BookingSource.walkIn) BookingSource source,
    @JsonKey(name: 'ota_reference') @Default('') String otaReference,
    @JsonKey(name: 'nightly_rate') required int nightlyRate,
    @JsonKey(name: 'deposit_amount') @Default(0) int depositAmount,
    @JsonKey(name: 'deposit_paid') @Default(false) bool depositPaid,
    @JsonKey(name: 'payment_method')
    @Default(PaymentMethod.cash)
        PaymentMethod paymentMethod,
    @Default('') String notes,
    @JsonKey(name: 'special_requests') @Default('') String specialRequests,
  }) = _BookingCreate;

  factory BookingCreate.fromJson(Map<String, dynamic> json) =>
      _$BookingCreateFromJson(json);

  const BookingCreate._();

  /// Convert to JSON for API
  Map<String, dynamic> toJson() => _$BookingCreateToJson(this as _BookingCreate);

  /// Calculate total amount
  int get totalAmount {
    final nights = checkOutDate.difference(checkInDate).inDays;
    return nightlyRate * nights;
  }

  /// Create from Booking model (for editing)
  factory BookingCreate.fromBooking(Booking booking) {
    return BookingCreate(
      room: booking.room,
      guest: booking.guest,
      checkInDate: booking.checkInDate,
      checkOutDate: booking.checkOutDate,
      guestCount: booking.guestCount,
      status: booking.status,
      source: booking.source,
      otaReference: booking.otaReference,
      nightlyRate: booking.nightlyRate,
      depositAmount: booking.depositAmount,
      depositPaid: booking.depositPaid,
      paymentMethod: booking.paymentMethod,
      notes: booking.notes,
      specialRequests: booking.specialRequests,
    );
  }
}

/// Model for updating an existing booking
@Freezed(toJson: true)
sealed class BookingUpdate with _$BookingUpdate {
  const factory BookingUpdate({
    @JsonKey(includeIfNull: false) int? room,
    @JsonKey(includeIfNull: false) int? guest,
    @JsonKey(name: 'check_in_date', includeIfNull: false) DateTime? checkInDate,
    @JsonKey(name: 'check_out_date', includeIfNull: false) DateTime? checkOutDate,
    @JsonKey(name: 'guest_count', includeIfNull: false) int? guestCount,
    @JsonKey(includeIfNull: false) BookingStatus? status,
    @JsonKey(includeIfNull: false) BookingSource? source,
    @JsonKey(name: 'ota_reference', includeIfNull: false) String? otaReference,
    @JsonKey(name: 'nightly_rate', includeIfNull: false) int? nightlyRate,
    @JsonKey(name: 'deposit_amount', includeIfNull: false) int? depositAmount,
    @JsonKey(name: 'deposit_paid', includeIfNull: false) bool? depositPaid,
    @JsonKey(name: 'additional_charges', includeIfNull: false) int? additionalCharges,
    @JsonKey(name: 'payment_method', includeIfNull: false) PaymentMethod? paymentMethod,
    @JsonKey(name: 'is_paid', includeIfNull: false) bool? isPaid,
    @JsonKey(includeIfNull: false) String? notes,
    @JsonKey(name: 'special_requests', includeIfNull: false) String? specialRequests,
  }) = _BookingUpdate;

  factory BookingUpdate.fromJson(Map<String, dynamic> json) =>
      _$BookingUpdateFromJson(json);

  const BookingUpdate._();

  /// Convert to JSON for API
  Map<String, dynamic> toJson() => _$BookingUpdateToJson(this as _BookingUpdate);

  /// Create from Booking model (for editing)
  factory BookingUpdate.fromBooking(Booking booking) {
    return BookingUpdate(
      room: booking.room,
      guest: booking.guest,
      checkInDate: booking.checkInDate,
      checkOutDate: booking.checkOutDate,
      guestCount: booking.guestCount,
      status: booking.status,
      source: booking.source,
      otaReference: booking.otaReference,
      nightlyRate: booking.nightlyRate,
      depositAmount: booking.depositAmount,
      depositPaid: booking.depositPaid,
      additionalCharges: booking.additionalCharges,
      paymentMethod: booking.paymentMethod,
      isPaid: booking.isPaid,
      notes: booking.notes,
      specialRequests: booking.specialRequests,
    );
  }
}
