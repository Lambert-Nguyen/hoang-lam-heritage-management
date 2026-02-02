import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'minibar.freezed.dart';
part 'minibar.g.dart';

// ============================================================
// Minibar Item Model
// ============================================================

/// Minibar item model matching backend MinibarItem
@freezed
sealed class MinibarItem with _$MinibarItem {
  const MinibarItem._();

  const factory MinibarItem({
    required int id,
    required String name,
    required double price,
    @Default(0) double cost,
    @Default('') String category,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MinibarItem;

  factory MinibarItem.fromJson(Map<String, dynamic> json) =>
      _$MinibarItemFromJson(json);

  /// Get profit margin
  double get profitMargin => price > 0 ? ((price - cost) / price) * 100 : 0;

  /// Format price for display
  String get formattedPrice => '${price.toStringAsFixed(0)} ₫';

  /// Format cost for display
  String get formattedCost => '${cost.toStringAsFixed(0)} ₫';
}

/// Minibar item list model for paginated response
@freezed
sealed class MinibarItemListResponse with _$MinibarItemListResponse {
  const factory MinibarItemListResponse({
    required int count,
    String? next,
    String? previous,
    required List<MinibarItem> results,
  }) = _MinibarItemListResponse;

  factory MinibarItemListResponse.fromJson(Map<String, dynamic> json) =>
      _$MinibarItemListResponseFromJson(json);
}

// ============================================================
// Minibar Sale Model
// ============================================================

/// Minibar sale model matching backend MinibarSale
@freezed
sealed class MinibarSale with _$MinibarSale {
  const MinibarSale._();

  const factory MinibarSale({
    required int id,
    required int booking,
    @JsonKey(name: 'booking_guest_name') String? bookingGuestName,
    @JsonKey(name: 'booking_room_number') String? bookingRoomNumber,
    required int item,
    @JsonKey(name: 'item_name') String? itemName,
    @JsonKey(name: 'item_category') String? itemCategory,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    required double total,
    required DateTime date,
    @JsonKey(name: 'is_charged') @Default(false) bool isCharged,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_name') String? createdByName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _MinibarSale;

  factory MinibarSale.fromJson(Map<String, dynamic> json) =>
      _$MinibarSaleFromJson(json);

  /// Format total for display
  String get formattedTotal => '${total.toStringAsFixed(0)} ₫';

  /// Format unit price for display
  String get formattedUnitPrice => '${unitPrice.toStringAsFixed(0)} ₫';

  /// Get display status
  String get statusText => isCharged ? 'Đã tính tiền' : 'Chưa tính tiền';

  /// Get status color
  Color get statusColor =>
      isCharged ? const Color(0xFF4CAF50) : const Color(0xFFFFC107);
}

/// Minibar sale list model for paginated response
@freezed
sealed class MinibarSaleListResponse with _$MinibarSaleListResponse {
  const factory MinibarSaleListResponse({
    required int count,
    String? next,
    String? previous,
    required List<MinibarSale> results,
  }) = _MinibarSaleListResponse;

  factory MinibarSaleListResponse.fromJson(Map<String, dynamic> json) =>
      _$MinibarSaleListResponseFromJson(json);
}

// ============================================================
// Request/Response Models
// ============================================================

/// Request model for creating minibar item
@freezed
sealed class CreateMinibarItemRequest with _$CreateMinibarItemRequest {
  const factory CreateMinibarItemRequest({
    required String name,
    required double price,
    @Default(0) double cost,
    @Default('') String category,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _CreateMinibarItemRequest;

  factory CreateMinibarItemRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMinibarItemRequestFromJson(json);
}

/// Request model for updating minibar item
@freezed
sealed class UpdateMinibarItemRequest with _$UpdateMinibarItemRequest {
  const factory UpdateMinibarItemRequest({
    String? name,
    double? price,
    double? cost,
    String? category,
    @JsonKey(name: 'is_active') bool? isActive,
  }) = _UpdateMinibarItemRequest;

  factory UpdateMinibarItemRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMinibarItemRequestFromJson(json);
}

/// Request model for creating minibar sale
@freezed
sealed class CreateMinibarSaleRequest with _$CreateMinibarSaleRequest {
  const factory CreateMinibarSaleRequest({
    required int booking,
    required int item,
    @Default(1) int quantity,
    required DateTime date,
  }) = _CreateMinibarSaleRequest;

  factory CreateMinibarSaleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMinibarSaleRequestFromJson(json);
}

/// Request model for bulk creating minibar sales
@freezed
sealed class BulkCreateMinibarSaleRequest with _$BulkCreateMinibarSaleRequest {
  const factory BulkCreateMinibarSaleRequest({
    required int booking,
    required List<MinibarSaleItem> items,
    DateTime? date,
  }) = _BulkCreateMinibarSaleRequest;

  factory BulkCreateMinibarSaleRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkCreateMinibarSaleRequestFromJson(json);
}

/// Item in bulk sale request
@freezed
sealed class MinibarSaleItem with _$MinibarSaleItem {
  const factory MinibarSaleItem({
    @JsonKey(name: 'item_id') required int itemId,
    required int quantity,
  }) = _MinibarSaleItem;

  factory MinibarSaleItem.fromJson(Map<String, dynamic> json) =>
      _$MinibarSaleItemFromJson(json);
}

/// Response model for charge all action
@freezed
sealed class ChargeAllResponse with _$ChargeAllResponse {
  const factory ChargeAllResponse({
    @JsonKey(name: 'charged_count') required int chargedCount,
    @JsonKey(name: 'total_amount') required double totalAmount,
  }) = _ChargeAllResponse;

  factory ChargeAllResponse.fromJson(Map<String, dynamic> json) =>
      _$ChargeAllResponseFromJson(json);
}

/// Response model for minibar sales summary
@freezed
sealed class MinibarSalesSummary with _$MinibarSalesSummary {
  const MinibarSalesSummary._();

  const factory MinibarSalesSummary({
    @JsonKey(name: 'total_sales') required int totalSales,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'charged_amount') required double chargedAmount,
    @JsonKey(name: 'uncharged_amount') required double unchargedAmount,
    required List<MinibarItemSummary> items,
  }) = _MinibarSalesSummary;

  factory MinibarSalesSummary.fromJson(Map<String, dynamic> json) =>
      _$MinibarSalesSummaryFromJson(json);

  /// Format total amount for display
  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(0)} ₫';

  /// Format charged amount for display
  String get formattedChargedAmount => '${chargedAmount.toStringAsFixed(0)} ₫';

  /// Format uncharged amount for display
  String get formattedUnchargedAmount =>
      '${unchargedAmount.toStringAsFixed(0)} ₫';
}

/// Item summary in sales summary response
@freezed
sealed class MinibarItemSummary with _$MinibarItemSummary {
  const factory MinibarItemSummary({
    @JsonKey(name: 'item__name') required String itemName,
    @JsonKey(name: 'total_quantity') required int totalQuantity,
    @JsonKey(name: 'total_amount') required double totalAmount,
  }) = _MinibarItemSummary;

  factory MinibarItemSummary.fromJson(Map<String, dynamic> json) =>
      _$MinibarItemSummaryFromJson(json);
}

// ============================================================
// Filter Models
// ============================================================

/// Filter parameters for minibar items
@freezed
sealed class MinibarItemFilter with _$MinibarItemFilter {
  const factory MinibarItemFilter({
    @JsonKey(name: 'is_active') bool? isActive,
    String? category,
    String? search,
  }) = _MinibarItemFilter;

  factory MinibarItemFilter.fromJson(Map<String, dynamic> json) =>
      _$MinibarItemFilterFromJson(json);
}

/// Filter parameters for minibar sales
@freezed
sealed class MinibarSaleFilter with _$MinibarSaleFilter {
  const factory MinibarSaleFilter({
    int? booking,
    int? room,
    @JsonKey(name: 'date_from') DateTime? dateFrom,
    @JsonKey(name: 'date_to') DateTime? dateTo,
    @JsonKey(name: 'is_charged') bool? isCharged,
  }) = _MinibarSaleFilter;

  factory MinibarSaleFilter.fromJson(Map<String, dynamic> json) =>
      _$MinibarSaleFilterFromJson(json);
}

// ============================================================
// Cart Model for POS
// ============================================================

/// Cart item for POS screen
@freezed
sealed class MinibarCartItem with _$MinibarCartItem {
  const MinibarCartItem._();

  const factory MinibarCartItem({
    required MinibarItem item,
    @Default(1) int quantity,
  }) = _MinibarCartItem;

  factory MinibarCartItem.fromJson(Map<String, dynamic> json) =>
      _$MinibarCartItemFromJson(json);

  /// Calculate total for this cart item
  double get total => item.price * quantity;

  /// Format total for display
  String get formattedTotal => '${total.toStringAsFixed(0)} ₫';
}
