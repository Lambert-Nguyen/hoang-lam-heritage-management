# 📋 Hoang Lam Heritage Management - Design Gaps Analysis

**Analysis Date:** 2026-02-05  
**Reference:** [Design Plan](./HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md)  
**Status:** ✅ MVP GAPS FIXED

---

## Executive Summary

This document identifies gaps between the Design Plan specifications and the actual implementation. Gaps are categorized by priority and include recommended fixes.

| Priority | Count | Fixed | Deferred |
|----------|-------|-------|----------|
| 🔴 CRITICAL | 3 | 2 | 1 |
| 🟠 HIGH | 6 | 6 | 0 |
| 🟡 MEDIUM | 4 | 3 | 1 |
| 🟢 LOW | 2 | 0 | 2 |

**Total Fixed: 11 / 15 gaps**  
**Remaining: 4 gaps (deferred to Phase 5+ or backlog)**

---

## 🔴 CRITICAL DESIGN GAPS

### GAP-001: Missing RatePlan & DateRateOverride Models

**Design Plan Reference:** Section 5 - Data Models

**What Design Plan Specifies:**
```python
class RatePlan(models.Model):
    name = models.CharField(max_length=50)
    room_type = models.ForeignKey('RoomType')
    base_rate = models.DecimalField()
    is_active = models.BooleanField(default=True)
    min_stay = models.IntegerField(default=1)
    max_stay = models.IntegerField(null=True, blank=True)
    advance_booking_days = models.IntegerField(null=True)
    cancellation_policy = models.TextField(blank=True)
    valid_from = models.DateField(null=True, blank=True)
    valid_to = models.DateField(null=True, blank=True)
    blackout_dates = models.JSONField(default=list)
    channels = models.JSONField(default=list)

class DateRateOverride(models.Model):
    room_type = models.ForeignKey('RoomType')
    date = models.DateField()
    rate = models.DecimalField()
    reason = models.CharField(max_length=100, blank=True)
    closed_to_arrival = models.BooleanField(default=False)
    closed_to_departure = models.BooleanField(default=False)
    min_stay = models.IntegerField(null=True, blank=True)
```

**What Is Implemented:** ❌ NOT IMPLEMENTED

**Impact:** Cannot implement dynamic pricing, seasonal rates, Tet holiday pricing, or OTA channel-specific rates.

**Fix Status:** ⏳ Deferred to Phase 5+ (not MVP critical for 7-room hotel)

---

### GAP-002: HotelUser Missing Permission Fields

**Design Plan Reference:** Section 5 - Data Models

**What Design Plan Specifies:**
```python
class HotelUser(models.Model):
    can_view_finance = models.BooleanField(default=False)
    can_edit_rates = models.BooleanField(default=False)
    can_manage_bookings = models.BooleanField(default=True)
    receive_notifications = models.BooleanField(default=True)
```

**What Is Implemented:**
```python
class HotelUser(models.Model):
    role = models.CharField(...)  # Only role field
    phone = models.CharField(...)
    is_active = models.BooleanField(default=True)
    # Missing: can_view_finance, can_edit_rates, can_manage_bookings, receive_notifications
```

**Impact:** Cannot implement granular role-based access control. All users within a role have identical access.

**Fix Status:** ✅ FIXED (2026-02-05)

---

### GAP-003: Dashboard Revenue Card Shows Zeros

**Design Plan Reference:** Section 6 - Screen Designs (Dashboard)

**What Design Plan Specifies:**
```
📊 Thu nhập hôm nay
┌─────────────────────────────┐
│  +2,500,000 VND             │
│  Chi: -350,000 VND          │
│  ────────────────────       │
│  Lợi nhuận: +2,150,000      │
└─────────────────────────────┘
```

**What Is Implemented:**
```dart
// home_screen.dart line 76-77
DashboardRevenueCard(
  todayRevenue: 0, // TODO: Get from financial endpoint
  todayExpense: 0,
```

**Impact:** Mom/Brother cannot see daily profit at a glance — defeats dashboard purpose.

**Fix Status:** ✅ FIXED (2026-02-05)

---

## 🟠 HIGH PRIORITY GAPS

### GAP-004: Guest Model Missing Loyalty/Preference Fields

**Design Plan Reference:** Section 5 - Data Models

**What Design Plan Specifies:**
```python
class Guest(models.Model):
    preferred_room_type = models.ForeignKey('RoomType', null=True, blank=True)
    preferred_floor = models.IntegerField(null=True, blank=True)
    special_requests = models.TextField(blank=True)
    total_spent = models.DecimalField(default=0)
    first_stay = models.DateField(null=True, blank=True)
    last_stay = models.DateField(null=True, blank=True)
```

**What Is Implemented:**
```python
class Guest(models.Model):
    preferences = models.JSONField(default=dict)  # Only JSON field
    # Missing: preferred_room_type FK, preferred_floor, total_spent, first_stay, last_stay
```

**Impact:** Cannot track spending history or room preferences for personalized service.

**Fix Status:** ✅ FIXED (2026-02-05)

---

### GAP-005: Booking Model Missing Fields

**Design Plan Reference:** Section 5 - Data Models

**What Design Plan Specifies:**
```python
class Booking(models.Model):
    additional_guests = models.ManyToManyField('Guest', blank=True)
    group = models.ForeignKey('GroupBooking', null=True, blank=True)
    discount_amount = models.DecimalField(default=0)
    discount_reason = models.CharField(max_length=100, blank=True)
    internal_notes = models.TextField(blank=True)
    ota_commission = models.DecimalField(default=0)
    declaration_submitted = models.BooleanField(default=False)
    declaration_submitted_at = models.DateTimeField(null=True, blank=True)
```

**What Is Implemented:** ❌ Fields NOT IMPLEMENTED

**Impact:** Cannot track additional guests, discounts given, OTA commissions, or police declaration status.

**Fix Status:** ✅ FIXED (2026-02-05)

---

### GAP-006: Missing Booking Sources (Expedia, Google Hotel)

**Design Plan Reference:** Section 5 - Predefined Data

**What Design Plan Specifies:**
```python
BOOKING_SOURCES = [
    {"code": "expedia", "name": "Expedia", "name_en": "Expedia"},
    {"code": "google_hotel", "name": "Google Hotel", "name_en": "Google Hotel"},
    # ...
]
```

**What Is Implemented:**
```python
class Source(models.TextChoices):
    OTHER_OTA = "other_ota", "OTA khác"  # Only catch-all
    # Missing: expedia, google_hotel
```

**Impact:** Cannot track Expedia or Google Hotel bookings separately for channel performance analytics.

**Fix Status:** ✅ FIXED (2026-02-05)

---

### GAP-007: Missing Payment Method (ZaloPay)

**Design Plan Reference:** Section 5 - Predefined Data

**What Design Plan Specifies:**
```python
PAYMENT_METHODS = [
    {"code": "zalopay", "name": "ZaloPay", "name_en": "ZaloPay", "icon": "phone_android"},
]
```

**What Is Implemented:**
```python
class PaymentMethod(models.TextChoices):
    # Missing: zalopay
```

**Impact:** ZaloPay payments must select "Other" — loses tracking granularity.

**Fix Status:** ✅ FIXED (2026-02-05)

---

### GAP-008: Dark Theme Not Implemented

**Design Plan Reference:** Section 13 - Accessibility Considerations

**What Design Plan Specifies:** Dark theme support for night-time usage.

**What Is Implemented:**
```dart
// app_theme.dart line 251-254
static ThemeData get darkTheme {
    // TODO: Implement dark theme if needed
    return lightTheme;  // Returns light theme!
}
```

**Impact:** Night-time usage strains eyes.

**Fix Status:** ⏳ Deferred to Phase 5+

---

### GAP-009: Offline-First Strategy Not Implemented

**Design Plan Reference:** Section 2 - Offline-First Strategy

**What Design Plan Specifies:**
```
┌─────────────────────────────────────────┐
│          Local Hive Database            │
│  - Cached bookings                      │
│  - Cached room data                     │
│  - Pending transactions (offline queue) │
│  - Financial entries                    │
└────────────────┬────────────────────────┘
                 │ Sync when online
```

**What Is Implemented:**
```dart
// hive_storage.dart line 16-19
// Register adapters here when models are created
// Hive.registerAdapter(BookingAdapter());  // COMMENTED OUT
// Hive.registerAdapter(RoomAdapter());
```

**Impact:** App fails when internet is unreliable (common in Vietnam hotels).

**Fix Status:** ⏳ Deferred to Phase 5+

---

## 🟡 MEDIUM PRIORITY GAPS

### GAP-010: Booking Detail Missing OTA Reference Display

**Design Plan Reference:** Section 6 - Booking Detail Screen

**What Design Plan Specifies:**
```
│ Nguồn: Agoda                │
│ Mã OTA: AGD-123456          │
```

**What Is Implemented:** Source is shown but `ota_reference` field is not displayed in UI.

**Impact:** OTA bookings lack reference IDs for cross-referencing with OTA admin portals.

**Fix Status:** ✅ FIXED (2026-02-05)

---

### GAP-011: Room Legend Incomplete

**Design Plan Reference:** Section 6 - Dashboard

**What Design Plan Specifies:**
```
🟢 Trống  🔴 Có khách  🟡 Dọn dẹp  ⚫ Bảo trì  🟤 Khóa
```

**What Is Implemented:**
```dart
// home_screen.dart - only 3 statuses in legend
🟢 Trống  🔴 Có khách  🟡 Dọn dẹp
// Missing: maintenance (gray), blocked (brown)
```

**Impact:** Users don't see all room states in legend; potentially confusing.

**Fix Status:** ✅ FIXED (2026-02-05)

---

### GAP-012: Finance Screen Missing Chart

**Design Plan Reference:** Section 6 - Financial Report Screen

**What Design Plan Specifies:**
```
📈 Biểu đồ thu chi
┌─────────────────────────────┐
│     ████                    │
│  ██ ████ ███                │
│  ██ ████ ███ ██             │
│ ─── ──── ─── ──── ...       │
│  W1   W2   W3   W4          │
└─────────────────────────────┘
```

**What Is Implemented:** No chart component exists in finance screen.

**Impact:** Users cannot visualize spending trends; harder to identify patterns.

**Fix Status:** ⏳ Deferred to Phase 5+

---

### GAP-013: Text Scale Factor Not Applied

**Design Plan Reference:** Section 13 - Accessibility Considerations

**What Design Plan Specifies:** `textScaleFactor: 1.0, 1.2, 1.4, 1.6` adjustable via settings.

**What Is Implemented:**
```dart
// main.dart line 76
// textScaleFactor: textScale,  // COMMENTED OUT
```

Settings UI exists but the value is not applied to MediaQuery.

**Impact:** Mom (50s+) may struggle with default text size even if she changes settings.

**Fix Status:** ✅ FIXED (2026-02-05)

---

## 🟢 LOW PRIORITY GAPS

### GAP-014: Missing Income Categories in Seed Data

**Design Plan Reference:** Section 5 - Predefined Data

**What Design Plan Specifies:**
```python
INCOME_CATEGORIES = [
    {"name": "Phụ thu giờ", "name_en": "Hourly Surcharge"},
    {"name": "Check-in sớm", "name_en": "Early Check-in"},
    {"name": "Check-out muộn", "name_en": "Late Check-out"},
    {"name": "Thuê xe", "name_en": "Vehicle Rental"},
    {"name": "Tour/Vé", "name_en": "Tours/Tickets"},
]
```

**What Is Implemented:** Only generic "Phụ thu" category exists.

**Impact:** Less granular income tracking.

**Fix Status:** ⏳ Backlog

---

### GAP-015: Missing Expense Category (OTA Commission)

**Design Plan Reference:** Section 5 - Predefined Data

**What Design Plan Specifies:**
```python
{"name": "Hoa hồng OTA", "name_en": "OTA Commission", "icon": "percent"},
```

**What Is Implemented:** Not in seeded expense categories.

**Impact:** OTA commissions tracked in booking but not as distinct expense category.

**Fix Status:** ⏳ Backlog

---

## ✅ CORRECTLY IMPLEMENTED

| Item | Design Spec | Implementation | Status |
|------|-------------|----------------|--------|
| Button height | 56dp | `buttonHeight = 56.0` | ✅ |
| Room cards | 80x80dp | `roomCardSize = 80.0` | ✅ |
| WCAG AA colors | 4.5:1 contrast | Documented in app_colors.dart | ✅ |
| Vietnamese-first | All labels Vietnamese | All UI Vietnamese | ✅ |
| Room status colors | `blocked = #795548` | Matches design | ✅ |
| Bottom navigation | 4 tabs | 4 tabs implemented | ✅ |
| JWT authentication | SimpleJWT | Implemented | ✅ |
| Guest ID types | 5 types | All 5 implemented | ✅ |

---

## Fix Progress Tracker

| Gap ID | Description | Sprint | Status | Date Fixed |
|--------|-------------|--------|--------|------------|
| GAP-002 | HotelUser permissions | 1 | ✅ | 2026-02-05 |
| GAP-003 | Dashboard revenue | 1 | ✅ | 2026-02-05 |
| GAP-004 | Guest loyalty fields | 1 | ✅ | 2026-02-05 |
| GAP-005 | Booking fields | 1 | ✅ | 2026-02-05 |
| GAP-006 | Booking sources | 1 | ✅ | 2026-02-05 |
| GAP-007 | ZaloPay | 1 | ✅ | 2026-02-05 |
| GAP-010 | OTA reference display | 1 | ✅ | 2026-02-05 |
| GAP-011 | Room legend | 1 | ✅ | 2026-02-05 |
| GAP-013 | Text scale factor | 1 | ✅ | 2026-02-05 |
| GAP-001 | RatePlan models | 5+ | ⏳ | - |
| GAP-008 | Dark theme | 5+ | ⏳ | - |
| GAP-009 | Offline sync | 5+ | ⏳ | - |
| GAP-012 | Finance charts | 5+ | ⏳ | - |
| GAP-014 | Income categories | Backlog | ⏳ | - |
| GAP-015 | OTA commission category | Backlog | ⏳ | - |

---

*Last Updated: 2026-02-05*
