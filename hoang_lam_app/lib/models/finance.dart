import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
}

/// Financial category model matching backend FinancialCategory
@freezed
class FinancialCategory with _$FinancialCategory {
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
class FinancialBookingDetails with _$FinancialBookingDetails {
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
class FinancialEntry with _$FinancialEntry {
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
    @JsonKey(name: 'payment_method') @Default(PaymentMethod.cash) PaymentMethod paymentMethod,
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
}

/// List entry for financial entries (lightweight)
@freezed
class FinancialEntryListItem with _$FinancialEntryListItem {
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
    @JsonKey(name: 'payment_method') @Default(PaymentMethod.cash) PaymentMethod paymentMethod,
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
class CategoryBreakdown with _$CategoryBreakdown {
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
class DailyFinancialSummary with _$DailyFinancialSummary {
  const DailyFinancialSummary._();

  const factory DailyFinancialSummary({
    required DateTime date,
    @JsonKey(name: 'total_income') required double totalIncome,
    @JsonKey(name: 'total_expense') required double totalExpense,
    @JsonKey(name: 'net_profit') required double netProfit,
    @JsonKey(name: 'income_entries') @Default(0) int incomeEntries,
    @JsonKey(name: 'expense_entries') @Default(0) int expenseEntries,
    @JsonKey(name: 'income_by_category') @Default([]) List<CategoryBreakdown> incomeByCategory,
    @JsonKey(name: 'expense_by_category') @Default([]) List<CategoryBreakdown> expenseByCategory,
  }) = _DailyFinancialSummary;

  factory DailyFinancialSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyFinancialSummaryFromJson(json);

  /// Get total number of entries
  int get totalEntries => incomeEntries + expenseEntries;

  /// Get profit margin percentage
  double get profitMargin => totalIncome > 0 ? (netProfit / totalIncome * 100) : 0;
}

/// Daily totals for charts
@freezed
class DailyTotals with _$DailyTotals {
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
class MonthlyFinancialSummary with _$MonthlyFinancialSummary {
  const MonthlyFinancialSummary._();

  const factory MonthlyFinancialSummary({
    required int year,
    required int month,
    @JsonKey(name: 'total_income') required double totalIncome,
    @JsonKey(name: 'total_expense') required double totalExpense,
    @JsonKey(name: 'net_profit') required double netProfit,
    @JsonKey(name: 'profit_margin') @Default(0) double profitMargin,
    @JsonKey(name: 'income_by_category') @Default([]) List<CategoryBreakdown> incomeByCategory,
    @JsonKey(name: 'expense_by_category') @Default([]) List<CategoryBreakdown> expenseByCategory,
    @JsonKey(name: 'daily_totals') @Default([]) List<DailyTotals> dailyTotals,
  }) = _MonthlyFinancialSummary;

  factory MonthlyFinancialSummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlyFinancialSummaryFromJson(json);

  /// Get formatted month name in Vietnamese
  String get monthName {
    const months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return months[month - 1];
  }

  /// Get formatted period string
  String get periodString => '$monthName, $year';
}

/// Request model for creating/updating financial entry
@freezed
class FinancialEntryRequest with _$FinancialEntryRequest {
  const factory FinancialEntryRequest({
    @JsonKey(name: 'entry_type') required EntryType entryType,
    required int category,
    required double amount,
    @Default('VND') String currency,
    @JsonKey(name: 'exchange_rate') @Default(1.0) double exchangeRate,
    required DateTime date,
    required String description,
    int? booking,
    @JsonKey(name: 'payment_method') @Default(PaymentMethod.cash) PaymentMethod paymentMethod,
    @JsonKey(name: 'receipt_number') String? receiptNumber,
  }) = _FinancialEntryRequest;

  factory FinancialEntryRequest.fromJson(Map<String, dynamic> json) =>
      _$FinancialEntryRequestFromJson(json);
}

/// Filter options for financial entries
@freezed
class FinancialEntryFilter with _$FinancialEntryFilter {
  const factory FinancialEntryFilter({
    EntryType? entryType,
    int? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    PaymentMethod? paymentMethod,
  }) = _FinancialEntryFilter;
}
