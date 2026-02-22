import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../l10n/app_localizations.dart';

part 'finance.freezed.dart';
part 'finance.g.dart';

/// Entry type for financial entries
enum EntryType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
}

/// Extension for EntryType display properties
extension EntryTypeExtension on EntryType {
  String get displayName {
    switch (this) {
      case EntryType.income:
        return 'Thu';
      case EntryType.expense:
        return 'Chi';
    }
  }

  String get displayNameEn {
    switch (this) {
      case EntryType.income:
        return 'Income';
      case EntryType.expense:
        return 'Expense';
    }
  }

  Color get color {
    switch (this) {
      case EntryType.income:
        return const Color(0xFF4CAF50); // Green
      case EntryType.expense:
        return const Color(0xFFF44336); // Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EntryType.income:
        return const Color(0xFFE8F5E9); // Green light
      case EntryType.expense:
        return const Color(0xFFFFEBEE); // Red light
    }
  }

  IconData get icon {
    switch (this) {
      case EntryType.income:
        return Icons.arrow_downward;
      case EntryType.expense:
        return Icons.arrow_upward;
    }
  }

  /// Convert to API value (snake_case)
  String get toApiValue => name;

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case EntryType.income:
        return l10n.entryTypeIncome;
      case EntryType.expense:
        return l10n.entryTypeExpense;
    }
  }
}

/// Payment method choices matching backend
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
        return Icons.payments;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.momo:
        return Icons.phone_android;
      case PaymentMethod.vnpay:
        return Icons.qr_code;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.otaCollect:
        return Icons.business;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  /// Convert to API value (snake_case)
  String get toApiValue {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.otaCollect:
        return 'ota_collect';
      default:
        return name;
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case PaymentMethod.cash:
        return l10n.paymentMethodCash;
      case PaymentMethod.bankTransfer:
        return l10n.paymentMethodBankTransfer;
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.card:
        return l10n.paymentMethodCard;
      case PaymentMethod.otaCollect:
        return l10n.paymentMethodOtaCollect;
      case PaymentMethod.other:
        return l10n.paymentMethodOther;
    }
  }
}

/// Financial category model matching backend FinancialCategory
@freezed
sealed class FinancialCategory with _$FinancialCategory {
  const FinancialCategory._();

  const factory FinancialCategory({
    required int id,
    required String name,
    @JsonKey(name: 'name_en') String? nameEn,
    @JsonKey(name: 'category_type') required EntryType categoryType,
    @Default('category') String icon,
    @Default('#808080') String color,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'entry_count') int? entryCount,
  }) = _FinancialCategory;

  factory FinancialCategory.fromJson(Map<String, dynamic> json) =>
      _$FinancialCategoryFromJson(json);

  /// Get IconData from icon string name
  IconData get iconData {
    return _iconMap[icon] ?? Icons.category;
  }

  /// Get Color from hex string
  Color get colorValue {
    try {
      final hexColor = color.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  static const Map<String, IconData> _iconMap = {
    'hotel': Icons.hotel,
    'payments': Icons.payments,
    'bolt': Icons.bolt,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'cleaning_services': Icons.cleaning_services,
    'restaurant': Icons.restaurant,
    'shopping_cart': Icons.shopping_cart,
    'build': Icons.build,
    'people': Icons.people,
    'receipt_long': Icons.receipt_long,
    'local_parking': Icons.local_parking,
    'local_laundry_service': Icons.local_laundry_service,
    'room_service': Icons.room_service,
    'local_bar': Icons.local_bar,
    'spa': Icons.spa,
    'directions_car': Icons.directions_car,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,
    'monetization_on': Icons.monetization_on,
    'attach_money': Icons.attach_money,
  };
}

/// Booking details embedded in financial entry
@freezed
sealed class FinancialBookingDetails with _$FinancialBookingDetails {
  const factory FinancialBookingDetails({
    required int id,
    @JsonKey(name: 'room_number') required String roomNumber,
    @JsonKey(name: 'guest_name') required String guestName,
    @JsonKey(name: 'check_in_date') required DateTime checkInDate,
    @JsonKey(name: 'check_out_date') required DateTime checkOutDate,
  }) = _FinancialBookingDetails;

  factory FinancialBookingDetails.fromJson(Map<String, dynamic> json) =>
      _$FinancialBookingDetailsFromJson(json);
}

/// Financial entry model matching backend FinancialEntry
@freezed
sealed class FinancialEntry with _$FinancialEntry {
  const FinancialEntry._();

  const factory FinancialEntry({
    required int id,
    @JsonKey(name: 'entry_type') required EntryType entryType,
    required int category,
    @JsonKey(name: 'category_details') FinancialCategory? categoryDetails,
    required double amount,
    @Default('VND') String currency,
    @JsonKey(name: 'exchange_rate') @Default(1.0) double exchangeRate,
    @JsonKey(name: 'amount_vnd') double? amountVnd,
    required DateTime date,
    required String description,
    int? booking,
    @JsonKey(name: 'booking_details') FinancialBookingDetails? bookingDetails,
    @JsonKey(name: 'payment_method')
    @Default(PaymentMethod.cash)
    PaymentMethod paymentMethod,
    @JsonKey(name: 'receipt_number') String? receiptNumber,
    String? attachment,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _FinancialEntry;

  factory FinancialEntry.fromJson(Map<String, dynamic> json) =>
      _$FinancialEntryFromJson(json);

  /// Get amount in VND
  double get amountInVnd => amountVnd ?? (amount * exchangeRate);

  /// Check if this is an income entry
  bool get isIncome => entryType == EntryType.income;

  /// Check if this is an expense entry
  bool get isExpense => entryType == EntryType.expense;

  /// Alias for date field (backward compatibility)
  DateTime get entryDate => date;

  /// Get category name from details
  String? get categoryName => categoryDetails?.name;

  /// Get category icon from details
  IconData? get categoryIcon => categoryDetails?.iconData;

  /// Get category color from details
  Color? get categoryColor => categoryDetails?.colorValue;

  /// Reference field - not stored in backend but needed for UI compatibility
  String get reference => receiptNumber ?? '';

  /// Notes field - alias for description
  String get notes => description;
}

/// List entry for financial entries (lightweight)
@freezed
sealed class FinancialEntryListItem with _$FinancialEntryListItem {
  const FinancialEntryListItem._();

  const factory FinancialEntryListItem({
    required int id,
    @JsonKey(name: 'entry_type') required EntryType entryType,
    required int category,
    @JsonKey(name: 'category_name') String? categoryName,
    @JsonKey(name: 'category_icon') String? categoryIcon,
    @JsonKey(name: 'category_color') String? categoryColor,
    required double amount,
    @Default('VND') String currency,
    required DateTime date,
    required String description,
    @JsonKey(name: 'payment_method')
    @Default(PaymentMethod.cash)
    PaymentMethod paymentMethod,
    @JsonKey(name: 'room_number') String? roomNumber,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _FinancialEntryListItem;

  factory FinancialEntryListItem.fromJson(Map<String, dynamic> json) =>
      _$FinancialEntryListItemFromJson(json);

  /// Get IconData from category icon string
  IconData get iconData {
    return FinancialCategory._iconMap[categoryIcon] ?? Icons.category;
  }

  /// Get Color from category color hex string
  Color get colorValue {
    try {
      final hexColor = (categoryColor ?? '#808080').replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Check if this is an income entry
  bool get isIncome => entryType == EntryType.income;

  /// Check if this is an expense entry
  bool get isExpense => entryType == EntryType.expense;
}

/// Category breakdown item for summaries
@freezed
sealed class CategoryBreakdown with _$CategoryBreakdown {
  const factory CategoryBreakdown({
    @JsonKey(name: 'category__name') required String categoryName,
    @JsonKey(name: 'category__icon') String? categoryIcon,
    @JsonKey(name: 'category__color') String? categoryColor,
    required double total,
  }) = _CategoryBreakdown;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CategoryBreakdownFromJson(json);
}

/// Daily financial summary
@freezed
sealed class DailyFinancialSummary with _$DailyFinancialSummary {
  const DailyFinancialSummary._();

  const factory DailyFinancialSummary({
    required DateTime date,
    @JsonKey(name: 'total_income') required double totalIncome,
    @JsonKey(name: 'total_expense') required double totalExpense,
    @JsonKey(name: 'net_profit') required double netProfit,
    @JsonKey(name: 'income_entries') @Default(0) int incomeEntries,
    @JsonKey(name: 'expense_entries') @Default(0) int expenseEntries,
    @JsonKey(name: 'income_by_category')
    @Default([])
    List<CategoryBreakdown> incomeByCategory,
    @JsonKey(name: 'expense_by_category')
    @Default([])
    List<CategoryBreakdown> expenseByCategory,
  }) = _DailyFinancialSummary;

  factory DailyFinancialSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyFinancialSummaryFromJson(json);

  /// Get total number of entries
  int get totalEntries => incomeEntries + expenseEntries;

  /// Get profit margin percentage
  double get profitMargin =>
      totalIncome > 0 ? (netProfit / totalIncome * 100) : 0;
}

/// Daily totals for charts
@freezed
sealed class DailyTotals with _$DailyTotals {
  const factory DailyTotals({
    required String day,
    @Default(0) double income,
    @Default(0) double expense,
  }) = _DailyTotals;

  factory DailyTotals.fromJson(Map<String, dynamic> json) =>
      _$DailyTotalsFromJson(json);
}

/// Monthly financial summary
@freezed
sealed class MonthlyFinancialSummary with _$MonthlyFinancialSummary {
  const MonthlyFinancialSummary._();

  const factory MonthlyFinancialSummary({
    required int year,
    required int month,
    @JsonKey(name: 'total_income') required double totalIncome,
    @JsonKey(name: 'total_expense') required double totalExpense,
    @JsonKey(name: 'net_profit') required double netProfit,
    @JsonKey(name: 'profit_margin') @Default(0) double profitMargin,
    @JsonKey(name: 'income_by_category')
    @Default([])
    List<CategoryBreakdown> incomeByCategory,
    @JsonKey(name: 'expense_by_category')
    @Default([])
    List<CategoryBreakdown> expenseByCategory,
    @JsonKey(name: 'daily_totals') @Default([]) List<DailyTotals> dailyTotals,
  }) = _MonthlyFinancialSummary;

  factory MonthlyFinancialSummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlyFinancialSummaryFromJson(json);

  /// Get formatted month name in Vietnamese
  String get monthName {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return months[month - 1];
  }

  /// Get formatted period string
  String get periodString => '$monthName, $year';

  /// Alias for netProfit (backward compatibility)
  double get netBalance => netProfit;
}

/// Request model for creating/updating financial entry
@freezed
sealed class FinancialEntryRequest with _$FinancialEntryRequest {
  const factory FinancialEntryRequest({
    @JsonKey(name: 'entry_type') required EntryType entryType,
    required int category,
    required double amount,
    @Default('VND') String currency,
    @JsonKey(name: 'exchange_rate') @Default(1.0) double exchangeRate,
    required DateTime date,
    required String description,
    int? booking,
    @JsonKey(name: 'payment_method')
    @Default(PaymentMethod.cash)
    PaymentMethod paymentMethod,
    @JsonKey(name: 'receipt_number') String? receiptNumber,
  }) = _FinancialEntryRequest;

  factory FinancialEntryRequest.fromJson(Map<String, dynamic> json) =>
      _$FinancialEntryRequestFromJson(json);
}

/// Filter options for financial entries
@freezed
sealed class FinancialEntryFilter with _$FinancialEntryFilter {
  const factory FinancialEntryFilter({
    EntryType? entryType,
    int? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    PaymentMethod? paymentMethod,
  }) = _FinancialEntryFilter;
}

// ============================================================
// Payment Models (Phase 2.1.3)
// ============================================================

/// Payment type enum matching backend Payment.PaymentType
enum PaymentType {
  @JsonValue('deposit')
  deposit,
  @JsonValue('room_charge')
  roomCharge,
  @JsonValue('extra_charge')
  extraCharge,
  @JsonValue('refund')
  refund,
  @JsonValue('adjustment')
  adjustment,
}

/// Extension for PaymentType display properties
extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.deposit:
        return 'Đặt cọc';
      case PaymentType.roomCharge:
        return 'Tiền phòng';
      case PaymentType.extraCharge:
        return 'Phí bổ sung';
      case PaymentType.refund:
        return 'Hoàn tiền';
      case PaymentType.adjustment:
        return 'Điều chỉnh';
    }
  }

  String get displayNameEn {
    switch (this) {
      case PaymentType.deposit:
        return 'Deposit';
      case PaymentType.roomCharge:
        return 'Room Charge';
      case PaymentType.extraCharge:
        return 'Extra Charge';
      case PaymentType.refund:
        return 'Refund';
      case PaymentType.adjustment:
        return 'Adjustment';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentType.deposit:
        return Icons.account_balance_wallet;
      case PaymentType.roomCharge:
        return Icons.hotel;
      case PaymentType.extraCharge:
        return Icons.add_shopping_cart;
      case PaymentType.refund:
        return Icons.money_off;
      case PaymentType.adjustment:
        return Icons.edit;
    }
  }

  Color get color {
    switch (this) {
      case PaymentType.deposit:
        return const Color(0xFF2196F3); // Blue
      case PaymentType.roomCharge:
        return const Color(0xFF4CAF50); // Green
      case PaymentType.extraCharge:
        return const Color(0xFFFF9800); // Orange
      case PaymentType.refund:
        return const Color(0xFFF44336); // Red
      case PaymentType.adjustment:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  /// Convert to API value (snake_case)
  String get toApiValue {
    switch (this) {
      case PaymentType.roomCharge:
        return 'room_charge';
      case PaymentType.extraCharge:
        return 'extra_charge';
      default:
        return name;
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case PaymentType.deposit:
        return l10n.paymentTypeDeposit;
      case PaymentType.roomCharge:
        return l10n.paymentTypeRoomCharge;
      case PaymentType.extraCharge:
        return l10n.paymentTypeExtraCharge;
      case PaymentType.refund:
        return l10n.paymentTypeRefund;
      case PaymentType.adjustment:
        return l10n.paymentTypeAdjustment;
    }
  }
}

/// Payment status enum matching backend Payment.Status
enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('refunded')
  refunded,
  @JsonValue('cancelled')
  cancelled,
}

/// Extension for PaymentStatus display properties
extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Chờ xử lý';
      case PaymentStatus.completed:
        return 'Hoàn tất';
      case PaymentStatus.failed:
        return 'Thất bại';
      case PaymentStatus.refunded:
        return 'Đã hoàn';
      case PaymentStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String get displayNameEn {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return const Color(0xFFFFC107); // Amber
      case PaymentStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case PaymentStatus.failed:
        return const Color(0xFFF44336); // Red
      case PaymentStatus.refunded:
        return const Color(0xFF9C27B0); // Purple
      case PaymentStatus.cancelled:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PaymentStatus.pending:
        return const Color(0xFFFFF8E1); // Amber light
      case PaymentStatus.completed:
        return const Color(0xFFE8F5E9); // Green light
      case PaymentStatus.failed:
        return const Color(0xFFFFEBEE); // Red light
      case PaymentStatus.refunded:
        return const Color(0xFFF3E5F5); // Purple light
      case PaymentStatus.cancelled:
        return const Color(0xFFECEFF1); // Blue Grey light
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case PaymentStatus.pending:
        return l10n.paymentStatusPending;
      case PaymentStatus.completed:
        return l10n.paymentStatusCompleted;
      case PaymentStatus.failed:
        return l10n.paymentStatusFailed;
      case PaymentStatus.refunded:
        return l10n.paymentStatusRefunded;
      case PaymentStatus.cancelled:
        return l10n.paymentStatusCancelled;
    }
  }
}

/// Payment model matching backend Payment model
@freezed
sealed class Payment with _$Payment {
  const Payment._();

  const factory Payment({
    required int id,
    required int booking,
    @JsonKey(name: 'booking_room') String? bookingRoom,
    @JsonKey(name: 'guest_name') String? guestName,
    @JsonKey(name: 'payment_type') required PaymentType paymentType,
    required double amount,
    @JsonKey(name: 'payment_method') required PaymentMethod paymentMethod,
    @Default(PaymentStatus.pending) PaymentStatus status,
    @JsonKey(name: 'receipt_number') String? receiptNumber,
    String? notes,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_name') String? createdByName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  /// Check if payment is completed
  bool get isCompleted => status == PaymentStatus.completed;

  /// Check if payment is deposit type
  bool get isDeposit => paymentType == PaymentType.deposit;
}

/// Request model for creating payment
@freezed
sealed class PaymentCreateRequest with _$PaymentCreateRequest {
  const factory PaymentCreateRequest({
    required int booking,
    @JsonKey(name: 'payment_type') required PaymentType paymentType,
    required double amount,
    @JsonKey(name: 'payment_method') required PaymentMethod paymentMethod,
    @Default(PaymentStatus.completed) PaymentStatus status,
    String? notes,
  }) = _PaymentCreateRequest;

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateRequestFromJson(json);
}

/// Deposit record request
@freezed
sealed class DepositRecordRequest with _$DepositRecordRequest {
  const factory DepositRecordRequest({
    required int booking,
    required double amount,
    @JsonKey(name: 'payment_method') required PaymentMethod paymentMethod,
    String? notes,
  }) = _DepositRecordRequest;

  factory DepositRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$DepositRecordRequestFromJson(json);
}

/// Outstanding deposit info for a booking
@freezed
sealed class OutstandingDeposit with _$OutstandingDeposit {
  const OutstandingDeposit._();

  const factory OutstandingDeposit({
    @JsonKey(name: 'booking_id') required int bookingId,
    @JsonKey(name: 'room_number') required String roomNumber,
    @JsonKey(name: 'guest_name') required String guestName,
    @JsonKey(name: 'check_in_date') required DateTime checkInDate,
    @JsonKey(name: 'check_out_date') required DateTime checkOutDate,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'required_deposit') required double requiredDeposit,
    @JsonKey(name: 'paid_deposit') required double paidDeposit,
    @JsonKey(name: 'outstanding') required double outstanding,
  }) = _OutstandingDeposit;

  factory OutstandingDeposit.fromJson(Map<String, dynamic> json) =>
      _$OutstandingDepositFromJson(json);

  /// Get the percentage of deposit paid
  double get paidPercentage =>
      requiredDeposit > 0 ? (paidDeposit / requiredDeposit * 100) : 0;

  /// Check if fully paid
  bool get isFullyPaid => outstanding <= 0;
}

// ============================================================
// Folio Item Models (Phase 2.1.4)
// ============================================================

/// Folio item type enum matching backend FolioItem.ItemType
enum FolioItemType {
  @JsonValue('room')
  room,
  @JsonValue('minibar')
  minibar,
  @JsonValue('laundry')
  laundry,
  @JsonValue('food')
  food,
  @JsonValue('service')
  service,
  @JsonValue('extra_bed')
  extraBed,
  @JsonValue('early_checkin')
  earlyCheckin,
  @JsonValue('late_checkout')
  lateCheckout,
  @JsonValue('damage')
  damage,
  @JsonValue('other')
  other,
}

/// Extension for FolioItemType display properties
extension FolioItemTypeExtension on FolioItemType {
  String get displayName {
    switch (this) {
      case FolioItemType.room:
        return 'Tiền phòng';
      case FolioItemType.minibar:
        return 'Minibar';
      case FolioItemType.laundry:
        return 'Giặt là';
      case FolioItemType.food:
        return 'Đồ ăn';
      case FolioItemType.service:
        return 'Dịch vụ';
      case FolioItemType.extraBed:
        return 'Giường phụ';
      case FolioItemType.earlyCheckin:
        return 'Nhận sớm';
      case FolioItemType.lateCheckout:
        return 'Trả muộn';
      case FolioItemType.damage:
        return 'Hư hỏng';
      case FolioItemType.other:
        return 'Khác';
    }
  }

  String get displayNameEn {
    switch (this) {
      case FolioItemType.room:
        return 'Room Charge';
      case FolioItemType.minibar:
        return 'Minibar';
      case FolioItemType.laundry:
        return 'Laundry';
      case FolioItemType.food:
        return 'Food & Beverage';
      case FolioItemType.service:
        return 'Service';
      case FolioItemType.extraBed:
        return 'Extra Bed';
      case FolioItemType.earlyCheckin:
        return 'Early Check-in';
      case FolioItemType.lateCheckout:
        return 'Late Checkout';
      case FolioItemType.damage:
        return 'Damage';
      case FolioItemType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case FolioItemType.room:
        return Icons.hotel;
      case FolioItemType.minibar:
        return Icons.local_bar;
      case FolioItemType.laundry:
        return Icons.local_laundry_service;
      case FolioItemType.food:
        return Icons.restaurant;
      case FolioItemType.service:
        return Icons.room_service;
      case FolioItemType.extraBed:
        return Icons.bed;
      case FolioItemType.earlyCheckin:
        return Icons.login;
      case FolioItemType.lateCheckout:
        return Icons.logout;
      case FolioItemType.damage:
        return Icons.warning;
      case FolioItemType.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case FolioItemType.room:
        return const Color(0xFF2196F3); // Blue
      case FolioItemType.minibar:
        return const Color(0xFFE91E63); // Pink
      case FolioItemType.laundry:
        return const Color(0xFF00BCD4); // Cyan
      case FolioItemType.food:
        return const Color(0xFFFF9800); // Orange
      case FolioItemType.service:
        return const Color(0xFF9C27B0); // Purple
      case FolioItemType.extraBed:
        return const Color(0xFF795548); // Brown
      case FolioItemType.earlyCheckin:
        return const Color(0xFF4CAF50); // Green
      case FolioItemType.lateCheckout:
        return const Color(0xFFFF5722); // Deep Orange
      case FolioItemType.damage:
        return const Color(0xFFF44336); // Red
      case FolioItemType.other:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  /// Convert to API value (snake_case)
  String get toApiValue {
    switch (this) {
      case FolioItemType.extraBed:
        return 'extra_bed';
      case FolioItemType.earlyCheckin:
        return 'early_checkin';
      case FolioItemType.lateCheckout:
        return 'late_checkout';
      default:
        return name;
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case FolioItemType.room:
        return l10n.folioTypeRoom;
      case FolioItemType.minibar:
        return l10n.folioTypeMinibar;
      case FolioItemType.laundry:
        return l10n.folioTypeLaundry;
      case FolioItemType.food:
        return l10n.folioTypeFood;
      case FolioItemType.service:
        return l10n.folioTypeService;
      case FolioItemType.extraBed:
        return l10n.folioTypeExtraBed;
      case FolioItemType.earlyCheckin:
        return l10n.folioTypeEarlyCheckin;
      case FolioItemType.lateCheckout:
        return l10n.folioTypeLateCheckout;
      case FolioItemType.damage:
        return l10n.folioTypeDamage;
      case FolioItemType.other:
        return l10n.folioTypeOther;
    }
  }
}

/// Folio item model matching backend FolioItem model
@freezed
sealed class FolioItem with _$FolioItem {
  const FolioItem._();

  const factory FolioItem({
    required int id,
    required int booking,
    @JsonKey(name: 'booking_room') String? bookingRoom,
    @JsonKey(name: 'item_type') required FolioItemType itemType,
    required String description,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'total_price') required double totalPrice,
    required DateTime date,
    @JsonKey(name: 'is_paid') @Default(false) bool isPaid,
    @JsonKey(name: 'is_voided') @Default(false) bool isVoided,
    @JsonKey(name: 'void_reason') String? voidReason,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_name') String? createdByName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _FolioItem;

  factory FolioItem.fromJson(Map<String, dynamic> json) =>
      _$FolioItemFromJson(json);

  /// Check if item is active (not voided)
  bool get isActive => !isVoided;
}

/// Request model for creating folio item
@freezed
sealed class FolioItemCreateRequest with _$FolioItemCreateRequest {
  const factory FolioItemCreateRequest({
    required int booking,
    @JsonKey(name: 'item_type') required FolioItemType itemType,
    required String description,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    required DateTime date,
  }) = _FolioItemCreateRequest;

  factory FolioItemCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$FolioItemCreateRequestFromJson(json);
}

/// Booking folio summary
@freezed
sealed class BookingFolioSummary with _$BookingFolioSummary {
  const BookingFolioSummary._();

  const factory BookingFolioSummary({
    @JsonKey(name: 'booking_id') required int bookingId,
    @JsonKey(name: 'room_number') required String roomNumber,
    @JsonKey(name: 'guest_name') required String guestName,
    @JsonKey(name: 'room_charges') required double roomCharges,
    @JsonKey(name: 'additional_charges') required double additionalCharges,
    @JsonKey(name: 'total_charges') required double totalCharges,
    @JsonKey(name: 'total_payments') required double totalPayments,
    required double balance,
    required List<FolioItem> items,
  }) = _BookingFolioSummary;

  factory BookingFolioSummary.fromJson(Map<String, dynamic> json) =>
      _$BookingFolioSummaryFromJson(json);

  /// Check if balance is settled
  bool get isSettled => balance <= 0;

  /// Get outstanding amount (positive means guest owes)
  double get outstandingAmount => balance > 0 ? balance : 0;
}

// ============================================================
// Exchange Rate Models (Phase 2.6)
// ============================================================

/// Exchange rate model matching backend ExchangeRate
@freezed
sealed class ExchangeRate with _$ExchangeRate {
  const ExchangeRate._();

  const factory ExchangeRate({
    required int id,
    @JsonKey(name: 'from_currency') required String fromCurrency,
    @JsonKey(name: 'to_currency') required String toCurrency,
    required double rate,
    required DateTime date,
    @Default('manual') String source,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ExchangeRate;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateFromJson(json);

  /// Get display string (e.g., "1 USD = 24,500 VND")
  String get displayString =>
      '1 $fromCurrency = ${rate.toStringAsFixed(2)} $toCurrency';

  /// Convert an amount using this rate
  double convert(double amount) => amount * rate;
}

/// Request model for creating exchange rate
@freezed
sealed class ExchangeRateCreateRequest with _$ExchangeRateCreateRequest {
  const factory ExchangeRateCreateRequest({
    @JsonKey(name: 'from_currency') required String fromCurrency,
    @JsonKey(name: 'to_currency') required String toCurrency,
    required double rate,
    required DateTime date,
    @Default('manual') String source,
  }) = _ExchangeRateCreateRequest;

  factory ExchangeRateCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateCreateRequestFromJson(json);
}

/// Currency conversion request
@freezed
sealed class CurrencyConversionRequest with _$CurrencyConversionRequest {
  const factory CurrencyConversionRequest({
    required double amount,
    @JsonKey(name: 'from_currency') required String fromCurrency,
    @JsonKey(name: 'to_currency') required String toCurrency,
  }) = _CurrencyConversionRequest;

  factory CurrencyConversionRequest.fromJson(Map<String, dynamic> json) =>
      _$CurrencyConversionRequestFromJson(json);
}

/// Currency conversion response
@freezed
sealed class CurrencyConversionResult with _$CurrencyConversionResult {
  const factory CurrencyConversionResult({
    @JsonKey(name: 'original_amount') required double originalAmount,
    @JsonKey(name: 'from_currency') required String fromCurrency,
    @JsonKey(name: 'to_currency') required String toCurrency,
    required double rate,
    @JsonKey(name: 'converted_amount') required double convertedAmount,
    required DateTime date,
  }) = _CurrencyConversionResult;

  factory CurrencyConversionResult.fromJson(Map<String, dynamic> json) =>
      _$CurrencyConversionResultFromJson(json);
}

// ============================================================
// Receipt Models (Phase 2.8)
// ============================================================

/// Receipt data model
@freezed
sealed class ReceiptData with _$ReceiptData {
  const ReceiptData._();

  const factory ReceiptData({
    @JsonKey(name: 'receipt_number') required String receiptNumber,
    @JsonKey(name: 'receipt_date') required DateTime receiptDate,
    @JsonKey(name: 'booking_id') required int bookingId,
    @JsonKey(name: 'room_number') required String roomNumber,
    @JsonKey(name: 'guest_name') required String guestName,
    @JsonKey(name: 'guest_phone') String? guestPhone,
    @JsonKey(name: 'guest_address') String? guestAddress,
    @JsonKey(name: 'check_in_date') required DateTime checkInDate,
    @JsonKey(name: 'check_out_date') required DateTime checkOutDate,
    @JsonKey(name: 'number_of_nights') required int numberOfNights,
    @JsonKey(name: 'nightly_rate') required double nightlyRate,
    @JsonKey(name: 'room_charges') required double roomCharges,
    @JsonKey(name: 'additional_charges') required double additionalCharges,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'deposit_paid') required double depositPaid,
    @JsonKey(name: 'balance_due') required double balanceDue,
    @JsonKey(name: 'payment_method') PaymentMethod? paymentMethod,
    @JsonKey(name: 'folio_items') @Default([]) List<FolioItem> folioItems,
    @JsonKey(name: 'payments') @Default([]) List<Payment> payments,
  }) = _ReceiptData;

  factory ReceiptData.fromJson(Map<String, dynamic> json) =>
      _$ReceiptDataFromJson(json);

  /// Check if balance is fully paid
  bool get isFullyPaid => balanceDue <= 0;

  /// Get total paid (deposit + other payments)
  double get totalPaid => totalAmount - balanceDue;
}

/// Request to generate receipt
@freezed
sealed class ReceiptGenerateRequest with _$ReceiptGenerateRequest {
  const factory ReceiptGenerateRequest({
    @JsonKey(name: 'booking_id') required int bookingId,
    @Default('VND') String currency,
  }) = _ReceiptGenerateRequest;

  factory ReceiptGenerateRequest.fromJson(Map<String, dynamic> json) =>
      _$ReceiptGenerateRequestFromJson(json);
}
