# 📚 Hoang Lam Heritage Management - API Reference

**Version:** 1.0 (MVP1)  
**Base URL:** `http://localhost:8000/api/v1`  
**Authentication:** JWT Bearer Token

---

## 📋 Table of Contents

1. [Authentication](#1-authentication)
2. [Rooms](#2-rooms)
3. [Room Types](#3-room-types)
4. [Guests](#4-guests)
5. [Bookings](#5-bookings)
6. [Financial Entries](#6-financial-entries)
7. [Payments](#7-payments)
8. [Folio Items](#8-folio-items)
9. [Housekeeping Tasks](#9-housekeeping-tasks)
10. [Maintenance Requests](#10-maintenance-requests)
11. [Minibar](#11-minibar)
12. [Night Audit](#12-night-audit)
13. [Reports](#13-reports)
14. [Exchange Rates](#14-exchange-rates)
15. [Lost & Found](#15-lost--found)
16. [Group Bookings](#16-group-bookings)
17. [Room Inspections](#17-room-inspections)
18. [Dashboard](#18-dashboard)
19. [Error Handling](#19-error-handling)

---

## Authentication

All endpoints except login require a valid JWT token in the Authorization header:

```
Authorization: Bearer <access_token>
```

### Token Lifecycle

| Token | Lifetime | Purpose |
|-------|----------|---------|
| Access Token | 60 minutes | API authentication |
| Refresh Token | 7 days | Obtain new access tokens |

---

## 1. Authentication

### POST `/auth/login/`

Login with username and password.

**Request:**
```json
{
  "username": "admin",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "first_name": "Admin",
    "last_name": "User",
    "role": "owner",
    "is_active": true
  }
}
```

---

### POST `/auth/refresh/`

Refresh access token.

**Request:**
```json
{
  "refresh": "<refresh_token>"
}
```

**Response (200):**
```json
{
  "access": "<new_access_token>"
}
```

---

### POST `/auth/logout/`

Invalidate tokens (blacklist refresh token).

**Request:**
```json
{
  "refresh": "<refresh_token>"
}
```

**Response (200):**
```json
{
  "detail": "Đăng xuất thành công"
}
```

---

### GET `/auth/me/`

Get current user profile.

**Response (200):**
```json
{
  "id": 1,
  "username": "admin",
  "email": "admin@example.com",
  "first_name": "Admin",
  "last_name": "User",
  "role": "owner",
  "phone": "0901234567",
  "is_active": true,
  "can_view_finance": true,
  "can_edit_rates": true,
  "receive_notifications": true
}
```

---

### POST `/auth/password/change/`

Change password.

**Request:**
```json
{
  "old_password": "current_password",
  "new_password": "new_secure_password"
}
```

**Response (200):**
```json
{
  "detail": "Đổi mật khẩu thành công"
}
```

---

## 2. Rooms

### GET `/rooms/`

List all rooms with optional filters.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status: `available`, `occupied`, `cleaning`, `maintenance`, `blocked` |
| `floor` | integer | Filter by floor number |
| `room_type` | integer | Filter by room type ID |
| `is_active` | boolean | Filter active/inactive rooms |

**Response (200):**
```json
{
  "count": 7,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "number": "101",
      "name": "Phòng Đơn 101",
      "room_type": 1,
      "room_type_name": "Phòng Đơn",
      "floor": 1,
      "status": "available",
      "status_display": "Trống",
      "amenities": ["wifi", "ac", "tv"],
      "notes": "",
      "is_active": true,
      "current_booking": null
    }
  ]
}
```

---

### GET `/rooms/{id}/`

Get room details.

**Response (200):**
```json
{
  "id": 1,
  "number": "101",
  "name": "Phòng Đơn 101",
  "room_type": 1,
  "room_type_name": "Phòng Đơn",
  "room_type_details": {
    "id": 1,
    "name": "Phòng Đơn",
    "base_rate": 350000,
    "hourly_rate": 80000,
    "max_guests": 1
  },
  "floor": 1,
  "status": "available",
  "status_display": "Trống",
  "amenities": ["wifi", "ac", "tv", "fridge"],
  "notes": "",
  "is_active": true,
  "current_booking": null,
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-02-04T08:30:00Z"
}
```

---

### PATCH `/rooms/{id}/`

Update room details.

**Request:**
```json
{
  "name": "Phòng VIP 101",
  "amenities": ["wifi", "ac", "tv", "fridge", "balcony"],
  "notes": "Phòng view đẹp"
}
```

---

### POST `/rooms/{id}/update_status/`

Change room status.

**Request:**
```json
{
  "status": "cleaning",
  "notes": "Đang dọn dẹp sau check-out"
}
```

**Response (200):**
```json
{
  "id": 1,
  "number": "101",
  "status": "cleaning",
  "status_display": "Đang dọn"
}
```

---

### GET `/rooms/{id}/availability/`

Check room availability for date range.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `check_in_date` | date | Yes | YYYY-MM-DD |
| `check_out_date` | date | Yes | YYYY-MM-DD |
| `exclude_booking` | integer | No | Booking ID to exclude |

**Response (200):**
```json
{
  "room_id": 1,
  "is_available": true,
  "conflicting_bookings": []
}
```

---

## 3. Room Types

### GET `/room-types/`

List all room types.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "name": "Phòng Đơn",
      "name_en": "Single Room",
      "base_rate": 350000,
      "hourly_rate": 80000,
      "first_hour_rate": 100000,
      "allows_hourly": true,
      "min_hours": 2,
      "max_guests": 1,
      "description": "Phòng đơn tiêu chuẩn",
      "amenities": ["wifi", "ac"],
      "room_count": 2,
      "available_count": 1
    }
  ]
}
```

---

## 4. Guests

### GET `/guests/`

List all guests with optional filters.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `search` | string | Search by name, phone, or ID number |
| `is_vip` | boolean | Filter VIP guests |
| `nationality` | string | Filter by nationality |

**Response (200):**
```json
{
  "count": 50,
  "results": [
    {
      "id": 1,
      "full_name": "Nguyễn Văn A",
      "phone": "0901234567",
      "email": "nguyenvana@email.com",
      "id_type": "cccd",
      "id_type_display": "CCCD",
      "id_number": "012345678901",
      "nationality": "Vietnam",
      "is_vip": false,
      "total_stays": 3,
      "created_at": "2026-01-10T10:00:00Z"
    }
  ]
}
```

---

### POST `/guests/`

Create a new guest.

**Request:**
```json
{
  "full_name": "Nguyễn Văn B",
  "phone": "0909876543",
  "email": "nguyenvanb@email.com",
  "id_type": "cccd",
  "id_number": "012345678902",
  "nationality": "Vietnam",
  "date_of_birth": "1990-05-15",
  "gender": "male",
  "address": "123 Đường ABC, Quận 1",
  "city": "Hồ Chí Minh"
}
```

**Response (201):**
```json
{
  "id": 2,
  "full_name": "Nguyễn Văn B",
  "phone": "0909876543",
  ...
}
```

---

### GET `/guests/{id}/history/`

Get guest's stay history.

**Response (200):**
```json
{
  "guest": {
    "id": 1,
    "full_name": "Nguyễn Văn A",
    "total_stays": 3,
    "total_spent": 2500000,
    "is_vip": false
  },
  "bookings": [
    {
      "id": 10,
      "room_number": "101",
      "check_in_date": "2026-01-20",
      "check_out_date": "2026-01-22",
      "total_amount": 700000,
      "status": "checked_out"
    }
  ]
}
```

---

### GET `/guests/search/`

Quick search for guests.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query (min 2 chars) |

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "full_name": "Nguyễn Văn A",
      "phone": "0901234567",
      "id_number": "012345678901"
    }
  ]
}
```

---

## 5. Bookings

### GET `/bookings/`

List bookings with filters.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | `pending`, `confirmed`, `checked_in`, `checked_out`, `cancelled`, `no_show` |
| `room` | integer | Room ID |
| `guest` | integer | Guest ID |
| `source` | string | `walk_in`, `phone`, `booking_com`, `agoda`, etc. |
| `check_in_date__gte` | date | Check-in from date |
| `check_in_date__lte` | date | Check-in to date |
| `booking_type` | string | `overnight`, `hourly` |

**Response (200):**
```json
{
  "count": 25,
  "results": [
    {
      "id": 1,
      "room": 1,
      "room_number": "101",
      "room_type_name": "Phòng Đơn",
      "guest": 1,
      "guest_name": "Nguyễn Văn A",
      "guest_phone": "0901234567",
      "check_in_date": "2026-02-05",
      "check_out_date": "2026-02-07",
      "actual_check_in": null,
      "actual_check_out": null,
      "booking_type": "overnight",
      "status": "confirmed",
      "status_display": "Đã xác nhận",
      "source": "walk_in",
      "source_display": "Khách vãng lai",
      "guest_count": 1,
      "nightly_rate": 350000,
      "total_amount": 700000,
      "deposit_amount": 200000,
      "deposit_paid": true,
      "is_paid": false,
      "nights": 2,
      "balance_due": 500000,
      "notes": "",
      "created_at": "2026-02-04T10:00:00Z"
    }
  ]
}
```

---

### POST `/bookings/`

Create a new booking.

**Request:**
```json
{
  "room": 1,
  "guest": 1,
  "check_in_date": "2026-02-10",
  "check_out_date": "2026-02-12",
  "booking_type": "overnight",
  "guest_count": 2,
  "source": "phone",
  "nightly_rate": 350000,
  "total_amount": 700000,
  "deposit_amount": 200000,
  "payment_method": "cash",
  "notes": "Khách yêu cầu phòng tầng cao",
  "special_requests": "Thêm gối"
}
```

**Response (201):**
```json
{
  "id": 5,
  "room": 1,
  "guest": 1,
  "status": "confirmed",
  ...
}
```

---

### POST `/bookings/{id}/check-in/`

Check in a guest.

**Request:**
```json
{
  "notes": "Khách đến đúng giờ",
  "deposit_amount": 500000,
  "payment_method": "cash"
}
```

**Response (200):**
```json
{
  "id": 1,
  "status": "checked_in",
  "actual_check_in": "2026-02-05T14:30:00Z",
  "deposit_amount": 500000,
  "deposit_paid": true
}
```

---

### POST `/bookings/{id}/check-out/`

Check out a guest.

**Request:**
```json
{
  "payment_method": "bank_transfer",
  "notes": "Thanh toán qua chuyển khoản"
}
```

**Response (200):**
```json
{
  "id": 1,
  "status": "checked_out",
  "actual_check_out": "2026-02-07T11:45:00Z",
  "total_amount": 700000,
  "additional_charges": 50000,
  "late_check_out_fee": 0,
  "balance_due": 0,
  "is_paid": true
}
```

---

### GET `/bookings/calendar/`

Get bookings for calendar view.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | date | Yes | YYYY-MM-DD |
| `end_date` | date | Yes | YYYY-MM-DD |

**Response (200):**
```json
{
  "bookings": [
    {
      "id": 1,
      "room": 1,
      "room_number": "101",
      "guest_name": "Nguyễn Văn A",
      "check_in_date": "2026-02-05",
      "check_out_date": "2026-02-07",
      "status": "confirmed",
      "source": "walk_in"
    }
  ]
}
```

---

### GET `/bookings/today/`

Get today's check-ins and check-outs.

**Response (200):**
```json
{
  "check_ins": [
    {
      "id": 5,
      "room_number": "102",
      "guest_name": "Trần Thị B",
      "expected_time": "14:00"
    }
  ],
  "check_outs": [
    {
      "id": 3,
      "room_number": "101",
      "guest_name": "Nguyễn Văn A",
      "expected_time": "12:00"
    }
  ]
}
```

---

## 6. Financial Entries

### GET `/finance/entries/`

List financial entries.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `entry_type` | string | `income`, `expense` |
| `category` | integer | Category ID |
| `date__gte` | date | From date |
| `date__lte` | date | To date |

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "entry_type": "income",
      "entry_type_display": "Thu",
      "category": 1,
      "category_name": "Tiền phòng",
      "amount": 700000,
      "currency": "VND",
      "date": "2026-02-05",
      "description": "Thanh toán phòng 101",
      "payment_method": "cash",
      "payment_method_display": "Tiền mặt",
      "booking": 1,
      "created_by_name": "Admin",
      "created_at": "2026-02-05T12:00:00Z"
    }
  ]
}
```

---

### POST `/finance/entries/`

Create financial entry.

**Request:**
```json
{
  "entry_type": "income",
  "category": 1,
  "amount": 500000,
  "currency": "VND",
  "date": "2026-02-05",
  "description": "Tiền cọc phòng 102",
  "payment_method": "momo",
  "booking": 5
}
```

---

### GET `/finance/categories/`

List financial categories.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "name": "Tiền phòng",
      "name_en": "Room Revenue",
      "category_type": "income",
      "icon": "hotel",
      "is_default": true
    },
    {
      "id": 10,
      "name": "Tiền điện",
      "name_en": "Electricity",
      "category_type": "expense",
      "icon": "bolt"
    }
  ]
}
```

---

## 7. Payments

### GET `/payments/`

List payments.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `booking` | integer | Filter by booking ID |
| `payment_type` | string | `room`, `deposit`, `service`, `refund` |
| `payment_method` | string | `cash`, `bank_transfer`, `momo`, `vnpay`, `card` |

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "booking": 1,
      "booking_info": {
        "room_number": "101",
        "guest_name": "Nguyễn Văn A"
      },
      "amount": 500000,
      "currency": "VND",
      "payment_type": "deposit",
      "payment_type_display": "Đặt cọc",
      "payment_method": "cash",
      "payment_method_display": "Tiền mặt",
      "reference_number": "",
      "is_refund": false,
      "notes": "",
      "received_by_name": "Admin",
      "created_at": "2026-02-05T10:30:00Z"
    }
  ]
}
```

---

### POST `/payments/`

Record a payment.

**Request:**
```json
{
  "booking": 1,
  "amount": 300000,
  "payment_type": "room",
  "payment_method": "bank_transfer",
  "reference_number": "VCB123456",
  "notes": "Thanh toán phần còn lại"
}
```

---

## 8. Folio Items

### GET `/folio-items/`

List folio items (charges to room).

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `booking` | integer | Filter by booking ID |
| `item_type` | string | `room`, `minibar`, `service`, `other` |

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "booking": 1,
      "item_type": "minibar",
      "item_type_display": "Minibar",
      "description": "Coca-Cola x2",
      "quantity": 2,
      "unit_price": 25000,
      "total_price": 50000,
      "date": "2026-02-06",
      "is_paid": false,
      "is_voided": false,
      "created_at": "2026-02-06T20:00:00Z"
    }
  ]
}
```

---

### POST `/folio-items/`

Add charge to folio.

**Request:**
```json
{
  "booking": 1,
  "item_type": "service",
  "description": "Giặt ủi",
  "quantity": 1,
  "unit_price": 100000,
  "date": "2026-02-06"
}
```

---

## 9. Housekeeping Tasks

### GET `/housekeeping-tasks/`

List housekeeping tasks.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | `pending`, `in_progress`, `completed`, `verified` |
| `task_type` | string | `checkout_clean`, `stay_clean`, `deep_clean`, `inspection` |
| `room` | integer | Room ID |
| `assigned_to` | integer | Staff user ID |
| `scheduled_date` | date | Date for task |

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "room": 1,
      "room_number": "101",
      "task_type": "checkout_clean",
      "task_type_display": "Dọn trả phòng",
      "status": "pending",
      "status_display": "Chờ thực hiện",
      "scheduled_date": "2026-02-05",
      "assigned_to": 3,
      "assigned_to_name": "Nhân viên A",
      "notes": "",
      "created_at": "2026-02-05T11:00:00Z"
    }
  ]
}
```

---

### POST `/housekeeping-tasks/{id}/start/`

Start working on a task.

**Response (200):**
```json
{
  "id": 1,
  "status": "in_progress",
  "started_at": "2026-02-05T11:30:00Z"
}
```

---

### POST `/housekeeping-tasks/{id}/complete/`

Complete a task.

**Request:**
```json
{
  "notes": "Đã dọn xong, thay khăn mới",
  "checklist_completed": true
}
```

**Response (200):**
```json
{
  "id": 1,
  "status": "completed",
  "completed_at": "2026-02-05T12:15:00Z"
}
```

---

## 10. Maintenance Requests

### GET `/maintenance-requests/`

List maintenance requests.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | `pending`, `assigned`, `in_progress`, `completed`, `on_hold`, `cancelled` |
| `priority` | string | `low`, `medium`, `high`, `urgent` |
| `category` | string | `electrical`, `plumbing`, `ac_heating`, `furniture`, etc. |
| `room` | integer | Room ID |

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "room": 1,
      "room_number": "101",
      "title": "Điều hòa không lạnh",
      "description": "Điều hòa bật nhưng không mát",
      "category": "ac_heating",
      "category_display": "Điều hòa/Sưởi",
      "priority": "high",
      "priority_display": "Cao",
      "status": "pending",
      "status_display": "Chờ xử lý",
      "estimated_cost": 500000,
      "actual_cost": null,
      "reported_by_name": "Staff A",
      "created_at": "2026-02-05T14:00:00Z"
    }
  ]
}
```

---

### POST `/maintenance-requests/`

Create maintenance request.

**Request:**
```json
{
  "room": 1,
  "title": "Vòi nước bị rò",
  "description": "Vòi nước phòng tắm bị rò rỉ",
  "category": "plumbing",
  "priority": "medium"
}
```

---

## 11. Minibar

### GET `/minibar-items/`

List minibar items.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "name": "Coca-Cola",
      "name_en": "Coca-Cola",
      "category": "beverage",
      "category_display": "Nước uống",
      "price": 25000,
      "cost": 15000,
      "is_active": true
    }
  ]
}
```

---

### GET `/minibar-sales/`

List minibar sales.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `booking` | integer | Filter by booking |
| `date__gte` | date | From date |
| `date__lte` | date | To date |

---

### POST `/minibar-sales/`

Record minibar sale.

**Request:**
```json
{
  "booking": 1,
  "items": [
    {"item": 1, "quantity": 2},
    {"item": 3, "quantity": 1}
  ],
  "charge_to_room": true
}
```

---

## 12. Night Audit

### GET `/night-audits/`

List night audit records.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "audit_date": "2026-02-04",
      "performed_by_name": "Admin",
      "rooms_occupied": 5,
      "rooms_available": 2,
      "occupancy_rate": 71.43,
      "room_revenue": 1750000,
      "other_revenue": 150000,
      "total_revenue": 1900000,
      "arrivals": 2,
      "departures": 1,
      "is_closed": true,
      "closed_at": "2026-02-04T23:30:00Z"
    }
  ]
}
```

---

### GET `/night-audits/current/`

Get current day audit (before closing).

**Response (200):**
```json
{
  "audit_date": "2026-02-05",
  "rooms_occupied": 4,
  "rooms_available": 3,
  "occupancy_rate": 57.14,
  "room_revenue": 1400000,
  "other_revenue": 75000,
  "total_revenue": 1475000,
  "arrivals": 1,
  "departures": 2,
  "pending_payments": [
    {"booking_id": 3, "amount": 200000}
  ],
  "pending_checkouts": [
    {"booking_id": 5, "room_number": "103"}
  ],
  "is_closed": false
}
```

---

### POST `/night-audits/close/`

Close the day.

**Request:**
```json
{
  "notes": "Ngày làm việc bình thường"
}
```

**Response (200):**
```json
{
  "id": 5,
  "audit_date": "2026-02-05",
  "is_closed": true,
  "closed_at": "2026-02-05T23:45:00Z"
}
```

---

## 13. Reports

### GET `/reports/occupancy/`

Occupancy report.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | date | Yes | YYYY-MM-DD |
| `end_date` | date | Yes | YYYY-MM-DD |
| `group_by` | string | No | `day`, `week`, `month` |

**Response (200):**
```json
{
  "summary": {
    "total_rooms": 7,
    "total_room_nights": 210,
    "occupied_room_nights": 150,
    "occupancy_rate": 71.43,
    "average_length_of_stay": 2.1
  },
  "by_period": [
    {"date": "2026-02-01", "occupied": 5, "available": 2, "rate": 71.43},
    {"date": "2026-02-02", "occupied": 6, "available": 1, "rate": 85.71}
  ],
  "by_room_type": [
    {"room_type": "Phòng Đơn", "occupied": 45, "rate": 64.29},
    {"room_type": "Phòng Đôi", "occupied": 80, "rate": 76.19}
  ]
}
```

---

### GET `/reports/revenue/`

Revenue report.

**Query Parameters:**
| Parameter | Type | Required |
|-----------|------|----------|
| `start_date` | date | Yes |
| `end_date` | date | Yes |
| `group_by` | string | No |

**Response (200):**
```json
{
  "summary": {
    "total_revenue": 45000000,
    "room_revenue": 42000000,
    "service_revenue": 2500000,
    "minibar_revenue": 500000
  },
  "by_source": [
    {"source": "walk_in", "source_display": "Khách vãng lai", "revenue": 20000000, "percentage": 44.44},
    {"source": "booking_com", "source_display": "Booking.com", "revenue": 15000000, "percentage": 33.33}
  ],
  "by_room": [
    {"room": "101", "revenue": 7000000},
    {"room": "102", "revenue": 8500000}
  ]
}
```

---

### GET `/reports/kpi/`

KPI metrics report.

**Response (200):**
```json
{
  "period": {
    "start_date": "2026-02-01",
    "end_date": "2026-02-28"
  },
  "metrics": {
    "occupancy_rate": 71.43,
    "adr": 450000,
    "revpar": 321429,
    "average_length_of_stay": 2.1,
    "booking_lead_time": 3.5
  },
  "comparison": {
    "occupancy_change": 5.2,
    "adr_change": -2.1,
    "revpar_change": 3.1
  }
}
```

---

### GET `/reports/export/`

Export report to file.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `report_type` | string | Yes | `occupancy`, `revenue`, `kpi`, `guests` |
| `start_date` | date | Yes | YYYY-MM-DD |
| `end_date` | date | Yes | YYYY-MM-DD |
| `format` | string | Yes | `csv`, `xlsx` |

**Response:** File download

---

## 14. Exchange Rates

### GET `/exchange-rates/`

List exchange rates.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "from_currency": "USD",
      "to_currency": "VND",
      "rate": 24500,
      "effective_date": "2026-02-05",
      "is_active": true
    }
  ]
}
```

---

### GET `/exchange-rates/latest/`

Get latest rates.

**Response (200):**
```json
{
  "USD_VND": 24500,
  "EUR_VND": 26800,
  "updated_at": "2026-02-05T08:00:00Z"
}
```

---

## 15. Lost & Found

### GET `/lost-found/`

List lost and found items.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "item_name": "iPhone 15",
      "description": "iPhone 15 Pro Max màu đen",
      "found_location": "Phòng 101",
      "found_date": "2026-02-04",
      "found_by_name": "Staff A",
      "status": "stored",
      "status_display": "Đang lưu giữ",
      "guest": 1,
      "guest_name": "Nguyễn Văn A"
    }
  ]
}
```

---

### POST `/lost-found/{id}/claim/`

Mark item as claimed.

**Request:**
```json
{
  "claimed_by_name": "Nguyễn Văn A",
  "claimed_by_phone": "0901234567",
  "notes": "Đã xác minh danh tính"
}
```

---

## 16. Group Bookings

### GET `/group-bookings/`

List group bookings.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "name": "Tour ABC",
      "contact_name": "Trần Văn C",
      "contact_phone": "0909999888",
      "check_in_date": "2026-02-10",
      "check_out_date": "2026-02-12",
      "room_count": 3,
      "total_guests": 6,
      "total_amount": 2100000,
      "status": "confirmed",
      "bookings": [1, 2, 3]
    }
  ]
}
```

---

## 17. Room Inspections

### GET `/room-inspections/`

List room inspections.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "room": 1,
      "room_number": "101",
      "inspection_type": "checkout",
      "inspection_type_display": "Kiểm tra trả phòng",
      "scheduled_date": "2026-02-05",
      "inspector_name": "Staff A",
      "status": "completed",
      "score": 95.0,
      "total_items": 20,
      "passed_items": 19,
      "issues_found": 1,
      "notes": "Một vết bẩn nhỏ trên thảm"
    }
  ]
}
```

---

### GET `/inspection-templates/`

List inspection templates.

**Response (200):**
```json
{
  "results": [
    {
      "id": 1,
      "name": "Kiểm tra chuẩn",
      "inspection_type": "checkout",
      "items": [
        {"name": "Giường gọn gàng", "category": "bedroom"},
        {"name": "Phòng tắm sạch", "category": "bathroom"}
      ]
    }
  ]
}
```

---

## 18. Dashboard

### GET `/dashboard/`

Get dashboard summary.

**Response (200):**
```json
{
  "date": "2026-02-05",
  "rooms": {
    "total": 7,
    "available": 3,
    "occupied": 4,
    "cleaning": 0,
    "maintenance": 0
  },
  "today": {
    "check_ins": 2,
    "check_outs": 1,
    "arrivals_pending": 1
  },
  "revenue": {
    "today": 1500000,
    "this_month": 32000000,
    "occupancy_rate": 71.43
  },
  "recent_bookings": [...],
  "urgent_tasks": [...]
}
```

---

## 19. Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Dữ liệu không hợp lệ",
    "details": {
      "phone": ["Số điện thoại đã tồn tại"]
    }
  }
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (successful delete) |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (invalid/expired token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 409 | Conflict (duplicate entry) |
| 500 | Internal Server Error |

### Common Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Input validation failed |
| `AUTHENTICATION_REQUIRED` | Token missing or invalid |
| `PERMISSION_DENIED` | User lacks permission |
| `NOT_FOUND` | Resource not found |
| `CONFLICT` | Duplicate or conflicting data |
| `ROOM_NOT_AVAILABLE` | Room is occupied or blocked |
| `INVALID_STATUS_TRANSITION` | Cannot change to this status |

---

## Rate Limiting

API requests are limited to:
- **100 requests/minute** per user
- **1000 requests/hour** per user

When exceeded, you'll receive:
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Quá nhiều yêu cầu. Vui lòng thử lại sau.",
    "retry_after": 60
  }
}
```

---

## Pagination

List endpoints return paginated results:

```json
{
  "count": 150,
  "next": "http://localhost:8000/api/v1/bookings/?page=2",
  "previous": null,
  "results": [...]
}
```

**Query Parameters:**
| Parameter | Default | Description |
|-----------|---------|-------------|
| `page` | 1 | Page number |
| `page_size` | 20 | Items per page (max 100) |

---

<p align="center">
  <strong>Hoang Lam Heritage Management API v1.0</strong><br/>
  © 2026 Hoang Lam Heritage Hotel
</p>
