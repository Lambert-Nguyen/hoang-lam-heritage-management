# Pricing Management - Hoàng Lâm Heritage Suites

## Overview

The pricing management system allows flexible configuration of room rates across different periods, days of the week, holidays, and special events. This document describes the backend models, API endpoints, and Flutter mobile screens for managing pricing.

## Architecture

### Backend Models (Django)

Located in `hoang_lam_backend/hotel_api/models.py`:

#### RatePlan

A rate plan defines pricing for a specific room type with validity periods and business rules.

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Primary key |
| `name` | string | Rate plan name (e.g., "Weekend Special", "Tet Holiday") |
| `room_type` | FK | Related room type |
| `base_rate` | decimal | Base rate for this plan (VND) |
| `min_stay` | int | Minimum nights required |
| `max_stay` | int | Maximum nights allowed |
| `cancellation_policy` | string | Policy code (flexible/moderate/strict/non_refundable) |
| `valid_from` | date | Start date of validity |
| `valid_to` | date | End date of validity |
| `blackout_dates` | string | JSON list of blackout dates where plan doesn't apply |
| `channels` | string | JSON list of channels (direct/ota/all) |
| `includes_breakfast` | bool | Whether breakfast is included |
| `is_active` | bool | Whether plan is active |
| `created_at` | datetime | Creation timestamp |
| `updated_at` | datetime | Last update timestamp |

#### DateRateOverride

Overrides the default rate for specific dates (holidays, special events, peak seasons).

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Primary key |
| `room_type` | FK | Related room type |
| `date` | date | The specific date for override |
| `rate` | decimal | Override rate (VND) |
| `reason` | string | Reason for override (e.g., "Tết Nguyên Đán", "Lễ 30/4 - 1/5") |
| `closed_to_arrival` | bool | Block check-ins on this date |
| `closed_to_departure` | bool | Block check-outs on this date |
| `min_stay` | int (nullable) | Override minimum stay requirement |
| `created_at` | datetime | Creation timestamp |

**Unique constraint:** `room_type` + `date` (one override per room type per date)

### API Endpoints

Base URL: `/api/v1/`

#### Rate Plans

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/rate-plans/` | List all rate plans |
| POST | `/rate-plans/` | Create a rate plan |
| GET | `/rate-plans/{id}/` | Retrieve a rate plan |
| PUT | `/rate-plans/{id}/` | Update a rate plan |
| DELETE | `/rate-plans/{id}/` | Delete a rate plan |

Query parameters:
- `room_type`: Filter by room type ID
- `is_active`: Filter by active status (true/false)
- `valid_from`: Filter plans valid from this date
- `valid_to`: Filter plans valid until this date

#### Date Rate Overrides

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/date-rate-overrides/` | List all date overrides |
| POST | `/date-rate-overrides/` | Create a date override |
| GET | `/date-rate-overrides/{id}/` | Retrieve a date override |
| PUT | `/date-rate-overrides/{id}/` | Update a date override |
| DELETE | `/date-rate-overrides/{id}/` | Delete a date override |
| POST | `/date-rate-overrides/bulk-create/` | Create multiple overrides at once |

Query parameters:
- `room_type`: Filter by room type ID
- `date_from`: Filter overrides from this date
- `date_to`: Filter overrides until this date

### Flutter Implementation

#### Models

Located in `hoang_lam_app/lib/models/rate_plan.dart`:

- `RatePlan` - Main rate plan model (Freezed)
- `RatePlanCreate` / `RatePlanUpdate` - Create/update DTOs
- `DateRateOverride` - Date override model (Freezed)
- `DateRateOverrideCreate` / `DateRateOverrideUpdate` - Create/update DTOs
- `DateRateOverrideListItem` - Lightweight list item with room type name
- `DecimalToDoubleConverter` - JSON converter for backend decimal strings

#### Repository

Located in `hoang_lam_app/lib/repositories/rate_plan_repository.dart`:

```dart
class RatePlanRepository {
  // Rate Plans
  Future<List<RatePlan>> getRatePlans({int? roomTypeId, bool? isActive});
  Future<RatePlan> getRatePlan(int id);
  Future<RatePlan> createRatePlan(RatePlanCreate data);
  Future<RatePlan> updateRatePlan(int id, RatePlanUpdate data);
  Future<void> deleteRatePlan(int id);
  
  // Date Rate Overrides
  Future<List<DateRateOverrideListItem>> getDateRateOverrides({int? roomTypeId});
  Future<DateRateOverride> getDateRateOverride(int id);
  Future<DateRateOverride> createDateRateOverride(DateRateOverrideCreate data);
  Future<DateRateOverride> updateDateRateOverride(int id, DateRateOverrideUpdate data);
  Future<void> deleteDateRateOverride(int id);
  Future<void> bulkCreateDateRateOverrides(List<DateRateOverrideCreate> data);
}
```

#### Providers

Located in `hoang_lam_app/lib/providers/rate_plan_provider.dart`:

- `ratePlanRepositoryProvider` - Repository provider
- `ratePlansProvider` - List of rate plans (FutureProvider)
- `dateRateOverridesProvider` - List of date overrides (FutureProvider)

#### Screens

Located in `hoang_lam_app/lib/screens/pricing/`:

1. **PricingManagementScreen** (`pricing_management_screen.dart`)
   - Tab-based interface with two tabs:
     - "Gói giá" (Rate Plans) - List of rate plans with room type filtering
     - "Giá theo ngày" (Date Overrides) - List of date-specific overrides
   - FAB button to create new items
   - Pull-to-refresh functionality
   - Delete with confirmation dialog

2. **RatePlanFormScreen** (`rate_plan_form_screen.dart`)
   - Create/edit form for rate plans
   - Fields: name, room type, base rate, min/max stay, cancellation policy
   - Date pickers for validity period
   - Channel selection (Direct, Booking.com, Agoda, etc.)
   - Breakfast toggle

3. **DateRateOverrideFormScreen** (`date_rate_override_form_screen.dart`)
   - Create/edit form for date overrides
   - Single date or bulk creation mode
   - Fields: room type, date(s), rate, reason
   - Closed to arrival/departure toggles
   - Min stay override

#### Routes

Added to `hoang_lam_app/lib/router/app_router.dart`:

| Route | Screen | Description |
|-------|--------|-------------|
| `/pricing` | PricingManagementScreen | Main pricing management |
| `/pricing/rate-plan/new` | RatePlanFormScreen | Create new rate plan |
| `/pricing/rate-plan/:id` | RatePlanFormScreen | Edit existing rate plan |
| `/pricing/date-override/new` | DateRateOverrideFormScreen | Create date override |
| `/pricing/date-override/:id` | DateRateOverrideFormScreen | Edit date override |

#### Navigation

Access from: **Settings Screen → Quản lý căn hộ → Quản lý giá**

## Use Cases

### 1. Setting Weekend Rates

Create a RatePlan with higher rates for Friday-Sunday:
1. Go to Pricing Management → Rate Plans tab
2. Tap "+" to create new rate plan
3. Name: "Weekend Rate"
4. Select room type
5. Set base_rate higher than weekday
6. Set valid_from and valid_to for the year
7. Select channels (Direct, OTA)
8. Save

### 2. Tet Holiday Pricing

Use DateRateOverride for specific holiday dates:
1. Go to Pricing Management → Date Overrides tab
2. Tap "+" to create new override
3. Enable "Bulk Create" mode
4. Select room type
5. Select date range (e.g., Feb 10-17 for Tet)
6. Enter holiday rate
7. Enter reason: "Tết Nguyên Đán 2025"
8. Optionally set min_stay = 3 for minimum 3-night booking
9. Save

### 3. Blocking Check-ins

Block arrivals on specific dates (e.g., renovation):
1. Create DateRateOverride
2. Enable "Closed to Arrival"
3. Set reason: "Bảo trì"

## Pricing Priority

When calculating room rates, the system uses this priority:
1. **DateRateOverride** - Highest priority, specific date overrides
2. **RatePlan** - Active rate plans for the booking period
3. **RoomType.base_rate** - Default room type rate

## Vietnamese Translations

| English | Vietnamese |
|---------|------------|
| Pricing Management | Quản lý giá |
| Rate Plans | Gói giá |
| Date Overrides | Giá theo ngày |
| Base Rate | Giá cơ bản |
| Min Stay | Số đêm tối thiểu |
| Max Stay | Số đêm tối đa |
| Cancellation Policy | Chính sách hủy |
| Flexible | Linh hoạt |
| Moderate | Trung bình |
| Strict | Nghiêm ngặt |
| Non-refundable | Không hoàn tiền |
| Valid From | Có hiệu lực từ |
| Valid To | Có hiệu lực đến |
| Includes Breakfast | Bao gồm bữa sáng |
| Closed to Arrival | Không nhận khách |
| Closed to Departure | Không trả phòng |
| Reason | Lý do |
| Weekend | Cuối tuần |
| Holiday | Ngày lễ |
| Special Price | Giá đặc biệt |

## Future Enhancements

1. **Calendar View** - Visual calendar showing date overrides
2. **Bulk Rate Update** - Update multiple room types at once
3. **Rate Shopping** - Monitor competitor pricing
4. **Dynamic Pricing** - Automatic rate adjustments based on occupancy
5. **Channel-specific Rates** - Different rates for different OTA channels
6. **Promotion Codes** - Discount codes for direct bookings
