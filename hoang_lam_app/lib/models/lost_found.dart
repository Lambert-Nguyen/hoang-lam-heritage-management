import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'lost_found.freezed.dart';
part 'lost_found.g.dart';

// ============================================================
// Lost & Found Status Enum
// ============================================================

enum LostFoundStatus {
  @JsonValue('found')
  found,
  @JsonValue('stored')
  stored,
  @JsonValue('claimed')
  claimed,
  @JsonValue('donated')
  donated,
  @JsonValue('disposed')
  disposed,
}

extension LostFoundStatusX on LostFoundStatus {
  String get displayName {
    switch (this) {
      case LostFoundStatus.found:
        return 'Đã tìm thấy';
      case LostFoundStatus.stored:
        return 'Đang lưu giữ';
      case LostFoundStatus.claimed:
        return 'Đã trả khách';
      case LostFoundStatus.donated:
        return 'Đã quyên góp';
      case LostFoundStatus.disposed:
        return 'Đã tiêu hủy';
    }
  }

  String get displayNameEn {
    switch (this) {
      case LostFoundStatus.found:
        return 'Found';
      case LostFoundStatus.stored:
        return 'Stored';
      case LostFoundStatus.claimed:
        return 'Claimed';
      case LostFoundStatus.donated:
        return 'Donated';
      case LostFoundStatus.disposed:
        return 'Disposed';
    }
  }

  Color get color {
    switch (this) {
      case LostFoundStatus.found:
        return Colors.blue;
      case LostFoundStatus.stored:
        return Colors.orange;
      case LostFoundStatus.claimed:
        return Colors.green;
      case LostFoundStatus.donated:
        return Colors.purple;
      case LostFoundStatus.disposed:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case LostFoundStatus.found:
        return Icons.search;
      case LostFoundStatus.stored:
        return Icons.inventory_2;
      case LostFoundStatus.claimed:
        return Icons.check_circle;
      case LostFoundStatus.donated:
        return Icons.volunteer_activism;
      case LostFoundStatus.disposed:
        return Icons.delete;
    }
  }
}

// ============================================================
// Lost & Found Category Enum
// ============================================================

enum LostFoundCategory {
  @JsonValue('electronics')
  electronics,
  @JsonValue('clothing')
  clothing,
  @JsonValue('jewelry')
  jewelry,
  @JsonValue('documents')
  documents,
  @JsonValue('money')
  money,
  @JsonValue('bags')
  bags,
  @JsonValue('personal')
  personal,
  @JsonValue('other')
  other,
}

extension LostFoundCategoryX on LostFoundCategory {
  String get displayName {
    switch (this) {
      case LostFoundCategory.electronics:
        return 'Đồ điện tử';
      case LostFoundCategory.clothing:
        return 'Quần áo';
      case LostFoundCategory.jewelry:
        return 'Trang sức';
      case LostFoundCategory.documents:
        return 'Giấy tờ';
      case LostFoundCategory.money:
        return 'Tiền';
      case LostFoundCategory.bags:
        return 'Túi/Vali';
      case LostFoundCategory.personal:
        return 'Đồ cá nhân';
      case LostFoundCategory.other:
        return 'Khác';
    }
  }

  String get displayNameEn {
    switch (this) {
      case LostFoundCategory.electronics:
        return 'Electronics';
      case LostFoundCategory.clothing:
        return 'Clothing';
      case LostFoundCategory.jewelry:
        return 'Jewelry';
      case LostFoundCategory.documents:
        return 'Documents';
      case LostFoundCategory.money:
        return 'Money';
      case LostFoundCategory.bags:
        return 'Bags/Luggage';
      case LostFoundCategory.personal:
        return 'Personal Items';
      case LostFoundCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case LostFoundCategory.electronics:
        return Icons.devices;
      case LostFoundCategory.clothing:
        return Icons.checkroom;
      case LostFoundCategory.jewelry:
        return Icons.diamond;
      case LostFoundCategory.documents:
        return Icons.description;
      case LostFoundCategory.money:
        return Icons.attach_money;
      case LostFoundCategory.bags:
        return Icons.luggage;
      case LostFoundCategory.personal:
        return Icons.person;
      case LostFoundCategory.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case LostFoundCategory.electronics:
        return Colors.blue;
      case LostFoundCategory.clothing:
        return Colors.pink;
      case LostFoundCategory.jewelry:
        return Colors.amber;
      case LostFoundCategory.documents:
        return Colors.brown;
      case LostFoundCategory.money:
        return Colors.green;
      case LostFoundCategory.bags:
        return Colors.teal;
      case LostFoundCategory.personal:
        return Colors.purple;
      case LostFoundCategory.other:
        return Colors.grey;
    }
  }
}

// ============================================================
// Lost & Found Model
// ============================================================

@freezed
sealed class LostFoundItem with _$LostFoundItem {
  const factory LostFoundItem({
    required int id,
    @JsonKey(name: 'item_name') required String itemName,
    @Default('') String description,
    required LostFoundCategory category,
    @JsonKey(name: 'category_display') String? categoryDisplay,
    @JsonKey(name: 'estimated_value') double? estimatedValue,
    // Location
    int? room,
    @JsonKey(name: 'room_number') String? roomNumber,
    @JsonKey(name: 'found_location') @Default('') String foundLocation,
    @JsonKey(name: 'storage_location') @Default('') String storageLocation,
    // Guest association
    int? guest,
    @JsonKey(name: 'guest_name') String? guestName,
    int? booking,
    // Status
    required LostFoundStatus status,
    @JsonKey(name: 'status_display') String? statusDisplay,
    @JsonKey(name: 'found_date') required String foundDate,
    @JsonKey(name: 'claimed_date') String? claimedDate,
    @JsonKey(name: 'disposed_date') String? disposedDate,
    // Staff
    @JsonKey(name: 'found_by') int? foundBy,
    @JsonKey(name: 'found_by_name') String? foundByName,
    @JsonKey(name: 'claimed_by_staff') int? claimedByStaff,
    @JsonKey(name: 'claimed_by_staff_name') String? claimedByStaffName,
    // Contact
    @JsonKey(name: 'guest_contacted') @Default(false) bool guestContacted,
    @JsonKey(name: 'contact_notes') @Default('') String contactNotes,
    // Image
    String? image,
    // Notes
    @Default('') String notes,
    // Audit
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _LostFoundItem;

  factory LostFoundItem.fromJson(Map<String, dynamic> json) =>
      _$LostFoundItemFromJson(json);
}

// ============================================================
// Lost & Found Create Model
// ============================================================

@freezed
sealed class LostFoundItemCreate with _$LostFoundItemCreate {
  const factory LostFoundItemCreate({
    @JsonKey(name: 'item_name') required String itemName,
    @Default('') String description,
    @Default(LostFoundCategory.other) LostFoundCategory category,
    @JsonKey(name: 'estimated_value') double? estimatedValue,
    // Location
    int? room,
    @JsonKey(name: 'found_location') @Default('') String foundLocation,
    @JsonKey(name: 'storage_location') @Default('') String storageLocation,
    // Guest association
    int? guest,
    int? booking,
    // Dates
    @JsonKey(name: 'found_date') required String foundDate,
    // Staff
    @JsonKey(name: 'found_by') int? foundBy,
    // Contact
    @JsonKey(name: 'guest_contacted') @Default(false) bool guestContacted,
    @JsonKey(name: 'contact_notes') @Default('') String contactNotes,
    // Notes
    @Default('') String notes,
  }) = _LostFoundItemCreate;

  factory LostFoundItemCreate.fromJson(Map<String, dynamic> json) =>
      _$LostFoundItemCreateFromJson(json);
}

// ============================================================
// Lost & Found Update Model
// ============================================================

@freezed
sealed class LostFoundItemUpdate with _$LostFoundItemUpdate {
  const factory LostFoundItemUpdate({
    @JsonKey(name: 'item_name') String? itemName,
    String? description,
    LostFoundCategory? category,
    @JsonKey(name: 'estimated_value') double? estimatedValue,
    // Location
    int? room,
    @JsonKey(name: 'found_location') String? foundLocation,
    @JsonKey(name: 'storage_location') String? storageLocation,
    // Guest association
    int? guest,
    int? booking,
    // Status
    LostFoundStatus? status,
    // Contact
    @JsonKey(name: 'guest_contacted') bool? guestContacted,
    @JsonKey(name: 'contact_notes') String? contactNotes,
    // Notes
    String? notes,
  }) = _LostFoundItemUpdate;

  factory LostFoundItemUpdate.fromJson(Map<String, dynamic> json) =>
      _$LostFoundItemUpdateFromJson(json);
}

// ============================================================
// Lost & Found Statistics Model
// ============================================================

@freezed
sealed class LostFoundStatistics with _$LostFoundStatistics {
  const factory LostFoundStatistics({
    @JsonKey(name: 'total_items') required int totalItems,
    @JsonKey(name: 'by_status') required Map<String, int> byStatus,
    @JsonKey(name: 'by_category') required Map<String, int> byCategory,
    @JsonKey(name: 'unclaimed_value') required double unclaimedValue,
    @JsonKey(name: 'recent_items') required List<LostFoundItem> recentItems,
  }) = _LostFoundStatistics;

  factory LostFoundStatistics.fromJson(Map<String, dynamic> json) =>
      _$LostFoundStatisticsFromJson(json);
}
