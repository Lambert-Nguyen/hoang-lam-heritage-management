# Hoang Lam Heritage Management - Design Plan

**Project Name:** Hoang Lam Heritage Management
**Created:** 2026-01-19
**Target Users:** Mom (iOS), Brother (Android)
**Scale:** 7 rooms, small family-run hotel
**Inspiration:** ezCloud.vn hotel management platform

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Project Architecture](#2-project-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Feature Roadmap](#4-feature-roadmap)
5. [Data Models](#5-data-models)
6. [Screen Designs](#6-screen-designs)
7. [OTA Integration Strategy](#7-ota-integration-strategy)
8. [Multi-Currency Support](#8-multi-currency-support)
9. [Security & Privacy](#9-security--privacy)
10. [Testing Strategy](#10-testing-strategy)
11. [Error Handling & Logging](#11-error-handling--logging)
12. [Backup & Recovery](#12-backup--recovery)
13. [Accessibility Considerations](#13-accessibility-considerations)
14. [Development Phases](#14-development-phases)
15. [Deployment Strategy](#15-deployment-strategy)

---

## 1. Executive Summary

### Goal
Build a simple, intuitive hotel management app for a 7-room family hotel that enables:
- **Booking Management:** Track reservations, walk-ins, and check-ins/check-outs
- **Financial Tracking:** Monitor income, expenses, and profitability
- **OTA Integration:** Connect with Booking.com, Agoda, Airbnb, and local platforms (future)

### Key Principles
1. **Simplicity First:** Users are not tech experts - UI must be intuitive
2. **Mobile-First:** Primary usage will be on phones
3. **Offline Capable:** Hotel may have unreliable internet
4. **Bilingual:** Vietnamese primary, English optional

### Repository Structure
```
NEW REPOSITORY: hotel-management/
├── hotel_app/              # Flutter mobile app
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── hotel_backend/          # Django REST API (can be added to cosmo_backend later)
│   ├── hotel_api/
│   ├── manage.py
│   └── requirements.txt
├── docs/
└── README.md
```

### Relationship with Cosmo Management
| Aspect | Approach |
|--------|----------|
| **Flutter App** | Separate repository, copy patterns from cosmo_app |
| **Backend** | Start separate, optionally merge into cosmo_backend later |
| **Authentication** | Can share JWT infrastructure if backends merge |
| **Database** | Separate PostgreSQL database |
| **Deployment** | Can share server, different ports/subdomains |

---

## 2. Project Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  ┌─────────┐  ┌──────────┐  ┌─────────┐  ┌───────────────┐  │
│  │ Bookings│  │  Rooms   │  │ Finance │  │    Reports    │  │
│  └─────────┘  └──────────┘  └─────────┘  └───────────────┘  │
├─────────────────────────────────────────────────────────────┤
│              Riverpod State Management                       │
│              Hive Local Storage (Offline)                    │
│              Dio HTTP Client                                 │
├─────────────────────────────────────────────────────────────┤
│                  Django REST API                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  /api/v1/bookings  /api/v1/rooms  /api/v1/finance   │    │
│  │  /api/v1/reports   /api/v1/ota    /api/v1/auth      │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                    PostgreSQL Database                       │
├─────────────────────────────────────────────────────────────┤
│           OTA Integrations (Future - Phase 4+)               │
│  ┌───────────┐ ┌───────┐ ┌────────┐ ┌──────────────────┐   │
│  │Booking.com│ │ Agoda │ │ Airbnb │ │ Local Platforms  │   │
│  └───────────┘ └───────┘ └────────┘ └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Offline-First Strategy
```
┌─────────────────────────────────────────┐
│          Local Hive Database            │
│  - Cached bookings                      │
│  - Cached room data                     │
│  - Pending transactions (offline queue) │
│  - Financial entries                    │
└────────────────┬────────────────────────┘
                 │ Sync when online
                 ▼
┌─────────────────────────────────────────┐
│           Django Backend                │
│  - Source of truth                      │
│  - Conflict resolution                  │
│  - OTA synchronization                  │
└─────────────────────────────────────────┘
```

---

## 3. Technology Stack

### Frontend (Flutter)
| Component | Technology | Reason |
|-----------|------------|--------|
| **Framework** | Flutter 3.x | Cross-platform (iOS + Android) |
| **State** | Riverpod 2.x | Proven in Cosmo, type-safe |
| **HTTP** | Dio 5.x | Interceptors, retry logic |
| **Local DB** | Hive 2.x | Fast, encrypted, offline support |
| **Routing** | GoRouter | Deep linking, navigation |
| **Models** | Freezed + json_serializable | Immutable, type-safe |
| **i18n** | flutter_localizations + intl | Vietnamese/English |
| **Charts** | fl_chart | Financial visualizations |
| **Calendar** | table_calendar | Booking calendar view |

### Backend (Django)
| Component | Technology | Reason |
|-----------|------------|--------|
| **Framework** | Django 5.x + DRF | Proven, rapid development |
| **Database** | PostgreSQL 15+ | Reliable, JSON support |
| **Auth** | JWT (SimpleJWT) | Stateless, mobile-friendly |
| **Task Queue** | Celery + Redis | OTA sync jobs |
| **OTA Sync** | Custom adapters | Booking.com, Agoda APIs |

---

## 4. Feature Roadmap

> Inspired by ezCloud.vn - comprehensive hotel management with OTA distribution, revenue optimization, and guest experience features.

### Phase 1: Core MVP (Foundation)
**Goal:** Basic booking and room management

| Feature | Priority | Description |
|---------|----------|-------------|
| User Authentication | P0 | Login for mom and brother (JWT) |
| Room Management | P0 | View/edit 7 rooms, status, rates |
| Manual Booking | P0 | Create walk-in and phone bookings |
| Booking Calendar | P0 | Visual calendar of occupancy |
| Check-in/Check-out | P0 | Mark guests as arrived/departed |
| Guest Information | P1 | Name, phone, ID number (CCCD) |
| Dashboard | P0 | Today's overview: rooms, check-ins/outs, revenue |

### Phase 2: Financial Tracking
**Goal:** Income and expense management (like ezCloud's revenue tools)

| Feature | Priority | Description |
|---------|----------|-------------|
| Income Recording | P0 | Room revenue, extra services |
| Expense Recording | P0 | Utilities, supplies, wages |
| Daily Summary | P0 | Today's income/expenses |
| Monthly Report | P1 | Revenue, expenses, profit |
| Multi-Currency | P1 | VND, USD support with exchange rates |
| Receipt/Invoice | P2 | Generate simple receipts |
| Payment Methods | P1 | Cash, bank transfer, MoMo, VNPay |

### Phase 3: Operations & Housekeeping
**Goal:** Complete hotel operations (ezCloud-inspired)

| Feature | Priority | Description |
|---------|----------|-------------|
| Housekeeping Tasks | P1 | Auto-create cleaning tasks on checkout |
| Room Status Tracking | P1 | Available → Occupied → Cleaning → Available |
| Minibar/POS | P2 | Sell items, charge to room |
| Minibar Inventory | P2 | Track minibar stock per room |
| Task Assignment | P2 | Assign cleaning tasks to staff |
| Maintenance Requests | P2 | Track room maintenance issues |

### Phase 4: Reports & Analytics
**Goal:** Business intelligence (like ezBi)

| Feature | Priority | Description |
|---------|----------|-------------|
| Occupancy Reports | P1 | Room utilization %, trends |
| Revenue Analytics | P1 | By room, by source, by month |
| RevPAR Calculation | P1 | Revenue per available room |
| Expense Analysis | P1 | Categorized spending breakdown |
| Export to Excel | P2 | Download reports |
| Comparative Reports | P2 | This month vs last month |

### Phase 5: Guest Communication
**Goal:** Customer experience (like ezMessage/ezGuest)

| Feature | Priority | Description |
|---------|----------|-------------|
| Booking Confirmations | P1 | Auto-send confirmation via SMS/email |
| Check-out Reminders | P1 | Push notifications for upcoming checkouts |
| Guest History | P2 | Track returning guests |
| Birthday/Special Dates | P3 | Send greetings (future) |

### Phase 6: OTA Integration (Channel Manager)
**Goal:** Connect with booking platforms (like ezCms)

| Feature | Priority | Description |
|---------|----------|-------------|
| iCal Sync | P1 | Simple calendar sync (Airbnb, Booking.com) |
| Booking.com API | P2 | Full channel manager integration |
| Agoda API | P2 | Southeast Asia bookings |
| Traveloka | P2 | Vietnam/SEA OTA |
| Rate Management | P2 | Sync prices across platforms |
| Availability Sync | P2 | Real-time room availability |
| Smart Pricing | P3 | Auto-adjust rates based on demand |

### Phase 7: Direct Booking (Future)
**Goal:** Reduce OTA commissions (like ezBe)

| Feature | Priority | Description |
|---------|----------|-------------|
| Booking Widget | P3 | Embeddable for website/Facebook |
| Online Payments | P3 | VNPay, MoMo integration |
| Promotions | P3 | Discount codes, special offers |

---

## 5. Data Models

### Core Models

```python
# Room Model
class Room(models.Model):
    number = models.CharField(max_length=10)  # "101", "102", etc.
    name = models.CharField(max_length=50)    # "Phòng Đôi 1"
    room_type = models.ForeignKey('RoomType')
    floor = models.IntegerField(default=1)
    status = models.CharField(choices=ROOM_STATUS)  # available, occupied, cleaning, maintenance
    amenities = models.JSONField(default=list)      # ["AC", "TV", "WiFi"]
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

class RoomType(models.Model):
    name = models.CharField(max_length=50)          # "Phòng Đơn", "Phòng Đôi"
    name_en = models.CharField(max_length=50)       # "Single", "Double"
    base_rate = models.DecimalField()               # Default nightly rate
    max_guests = models.IntegerField(default=2)
    description = models.TextField(blank=True)

# Booking Model
class Booking(models.Model):
    room = models.ForeignKey('Room')
    guest_name = models.CharField(max_length=100)
    guest_phone = models.CharField(max_length=20, blank=True)
    guest_id_number = models.CharField(max_length=20, blank=True)  # CCCD/Passport
    guest_count = models.IntegerField(default=1)

    check_in_date = models.DateField()
    check_out_date = models.DateField()
    actual_check_in = models.DateTimeField(null=True)   # When they actually arrived
    actual_check_out = models.DateTimeField(null=True)  # When they actually left

    status = models.CharField(choices=BOOKING_STATUS)
    # BOOKING_STATUS: pending, confirmed, checked_in, checked_out, cancelled, no_show

    source = models.CharField(choices=BOOKING_SOURCE)
    # BOOKING_SOURCE: walk_in, phone, booking_com, agoda, airbnb, other

    ota_reference = models.CharField(max_length=50, blank=True)  # OTA booking ID

    # Pricing
    nightly_rate = models.DecimalField()
    currency = models.CharField(max_length=3, default='VND')
    total_amount = models.DecimalField()
    deposit_amount = models.DecimalField(default=0)
    deposit_paid = models.BooleanField(default=False)

    notes = models.TextField(blank=True)
    created_by = models.ForeignKey('User')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

# Financial Models
class FinancialEntry(models.Model):
    entry_type = models.CharField(choices=ENTRY_TYPE)  # income, expense
    category = models.ForeignKey('FinancialCategory')
    amount = models.DecimalField()
    currency = models.CharField(max_length=3, default='VND')
    exchange_rate = models.DecimalField(default=1)     # To VND

    date = models.DateField()
    description = models.TextField()

    # Link to booking (for room income)
    booking = models.ForeignKey('Booking', null=True, blank=True)

    # Payment details
    payment_method = models.CharField(choices=PAYMENT_METHOD)
    # PAYMENT_METHOD: cash, bank_transfer, momo, other

    receipt_number = models.CharField(max_length=50, blank=True)
    attachment = models.ImageField(null=True, blank=True)  # Receipt photo

    created_by = models.ForeignKey('User')
    created_at = models.DateTimeField(auto_now_add=True)

class FinancialCategory(models.Model):
    name = models.CharField(max_length=50)      # "Tiền điện", "Tiền nước"
    name_en = models.CharField(max_length=50)   # "Electricity", "Water"
    category_type = models.CharField(choices=['income', 'expense'])
    icon = models.CharField(max_length=50)      # Material icon name
    color = models.CharField(max_length=7)      # Hex color
    is_default = models.BooleanField(default=False)

# User Model
class HotelUser(models.Model):
    user = models.OneToOneField('auth.User')
    role = models.CharField(choices=USER_ROLE)  # owner, manager, staff
    phone = models.CharField(max_length=20)
    is_active = models.BooleanField(default=True)
```

### Predefined Data

```python
# Default Room Types
ROOM_TYPES = [
    {"name": "Phòng Đơn", "name_en": "Single Room", "max_guests": 1},
    {"name": "Phòng Đôi", "name_en": "Double Room", "max_guests": 2},
    {"name": "Phòng Gia Đình", "name_en": "Family Room", "max_guests": 4},
]

# Default Financial Categories
EXPENSE_CATEGORIES = [
    {"name": "Tiền điện", "name_en": "Electricity", "icon": "bolt"},
    {"name": "Tiền nước", "name_en": "Water", "icon": "water_drop"},
    {"name": "Internet/TV", "name_en": "Internet/TV", "icon": "wifi"},
    {"name": "Vật tư phòng", "name_en": "Room Supplies", "icon": "inventory"},
    {"name": "Giặt là", "name_en": "Laundry", "icon": "local_laundry_service"},
    {"name": "Bảo trì", "name_en": "Maintenance", "icon": "build"},
    {"name": "Lương nhân viên", "name_en": "Staff Wages", "icon": "payments"},
    {"name": "Thuế/Phí", "name_en": "Tax/Fees", "icon": "receipt"},
    {"name": "Khác", "name_en": "Other", "icon": "more_horiz"},
]

INCOME_CATEGORIES = [
    {"name": "Tiền phòng", "name_en": "Room Revenue", "icon": "hotel"},
    {"name": "Dịch vụ thêm", "name_en": "Extra Services", "icon": "room_service"},
    {"name": "Đồ ăn/Thức uống", "name_en": "Food/Beverage", "icon": "restaurant"},
    {"name": "Khác", "name_en": "Other", "icon": "more_horiz"},
]
```

### Database Schema Diagram
```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│  RoomType   │────<│    Room     │────<│    Booking      │
├─────────────┤     ├─────────────┤     ├─────────────────┤
│ id          │     │ id          │     │ id              │
│ name        │     │ number      │     │ room_id (FK)    │
│ name_en     │     │ name        │     │ guest_name      │
│ base_rate   │     │ room_type_id│     │ check_in_date   │
│ max_guests  │     │ floor       │     │ check_out_date  │
└─────────────┘     │ status      │     │ status          │
                    │ amenities   │     │ source          │
                    └─────────────┘     │ total_amount    │
                                        │ created_by (FK) │
                                        └────────┬────────┘
                                                 │
┌───────────────────┐     ┌─────────────────────┴────────┐
│ FinancialCategory │────<│      FinancialEntry          │
├───────────────────┤     ├──────────────────────────────┤
│ id                │     │ id                           │
│ name              │     │ entry_type (income/expense)  │
│ name_en           │     │ category_id (FK)             │
│ category_type     │     │ amount                       │
│ icon              │     │ currency                     │
└───────────────────┘     │ date                         │
                          │ booking_id (FK, nullable)    │
                          │ payment_method               │
                          │ created_by (FK)              │
                          └──────────────────────────────┘

┌─────────────┐
│ HotelUser   │
├─────────────┤
│ id          │
│ user_id(FK) │ ──> Django auth.User
│ role        │
│ phone       │
└─────────────┘
```

---

## 6. Screen Designs

### Navigation Structure
```
Bottom Navigation (4 tabs):
┌─────────┬─────────┬─────────┬─────────┐
│  Home   │ Bookings│ Finance │ Settings│
│   🏠    │   📅    │   💰    │   ⚙️    │
└─────────┴─────────┴─────────┴─────────┘
```

### Screen List

#### Tab 1: Home (Dashboard)
```
┌─────────────────────────────────────┐
│  Nhà Nghỉ ABC          [👤 Profile] │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Hôm nay - 19/01/2026        │    │
│  │ ┌───────┐ ┌───────┐         │    │
│  │ │ 3/7   │ │ 2     │         │    │
│  │ │Phòng  │ │Check- │         │    │
│  │ │trống  │ │out    │         │    │
│  │ └───────┘ └───────┘         │    │
│  └─────────────────────────────┘    │
│                                     │
│  📊 Thu nhập hôm nay               │
│  ┌─────────────────────────────┐    │
│  │  +2,500,000 VND             │    │
│  │  Chi: -350,000 VND          │    │
│  │  ────────────────────       │    │
│  │  Lợi nhuận: +2,150,000      │    │
│  └─────────────────────────────┘    │
│                                     │
│  🛏️ Trạng thái phòng              │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ 101 │ │ 102 │ │ 103 │ │ 104 │   │
│  │ 🟢  │ │ 🔴  │ │ 🔴  │ │ 🟢  │   │
│  └─────┘ └─────┘ └─────┘ └─────┘   │
│  ┌─────┐ ┌─────┐ ┌─────┐           │
│  │ 201 │ │ 202 │ │ 203 │           │
│  │ 🔴  │ │ 🟢  │ │ 🟡  │           │
│  └─────┘ └─────┘ └─────┘           │
│                                     │
│  🟢 Trống  🔴 Có khách  🟡 Dọn dẹp │
│                                     │
│  ⏰ Sắp check-out                  │
│  ┌─────────────────────────────┐    │
│  │ 🛏️ 102 - Nguyễn Văn A       │    │
│  │    Check-out: 12:00 hôm nay │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🛏️ 103 - Trần Thị B         │    │
│  │    Check-out: 12:00 hôm nay │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
        [+ Đặt phòng mới]  (FAB)
```

#### Tab 2: Bookings
```
┌─────────────────────────────────────┐
│  Đặt phòng              [🔍][📅]   │
├─────────────────────────────────────┤
│                                     │
│  ◀ Tháng 1, 2026 ▶                 │
│  ┌─────────────────────────────┐    │
│  │ CN T2 T3 T4 T5 T6 T7        │    │
│  │    1  2  3  4  5  6         │    │
│  │  7  8  9 10 11 12 13        │    │
│  │ 14 15 16 17 18 [19] 20      │    │
│  │ 21 22 23 24 25 26 27        │    │
│  │ 28 29 30 31                 │    │
│  └─────────────────────────────┘    │
│                                     │
│  Booking ngày 19/01:               │
│  ┌─────────────────────────────┐    │
│  │ 🟢 Check-in                 │    │
│  │ 102 - Nguyễn Văn C          │    │
│  │ 19/01 → 21/01 (2 đêm)       │    │
│  │ Booking.com • 1,200,000đ    │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🔴 Check-out                │    │
│  │ 103 - Trần Thị B            │    │
│  │ 17/01 → 19/01 (2 đêm)       │    │
│  │ Walk-in • 800,000đ          │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── Danh sách đặt phòng ──         │
│  [Tất cả ▼] [Đang ở] [Sắp đến]    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🛏️ 201 • Lê Văn D           │    │
│  │ 18/01 - 22/01 • Đang ở      │    │
│  │ Agoda • 2,400,000đ      [>] │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
        [+ Đặt phòng mới]  (FAB)
```

#### Tab 3: Finance
```
┌─────────────────────────────────────┐
│  Tài chính              [📊 Báo cáo]│
├─────────────────────────────────────┤
│                                     │
│  Tháng 1, 2026                     │
│  ┌─────────────────────────────┐    │
│  │ Thu nhập     +45,600,000đ   │    │
│  │ Chi phí      -12,350,000đ   │    │
│  │ ─────────────────────────   │    │
│  │ Lợi nhuận    +33,250,000đ   │    │
│  │                             │    │
│  │ [========     ] 73% margin  │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── Giao dịch gần đây ──           │
│  [Tất cả] [Thu] [Chi]              │
│                                     │
│  Hôm nay                           │
│  ┌─────────────────────────────┐    │
│  │ 🟢 +800,000đ                │    │
│  │ Tiền phòng - 103 Check-out  │    │
│  │ Tiền mặt • 10:30            │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🔴 -150,000đ                │    │
│  │ Vật tư phòng - Khăn tắm     │    │
│  │ Tiền mặt • 09:15            │    │
│  └─────────────────────────────┘    │
│                                     │
│  Hôm qua                           │
│  ┌─────────────────────────────┐    │
│  │ 🟢 +1,200,000đ              │    │
│  │ Tiền phòng - 201 Deposit    │    │
│  │ Chuyển khoản • 18:20        │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
   [+ Thu]              [+ Chi]  (FABs)
```

#### Booking Detail Screen
```
┌─────────────────────────────────────┐
│  ← Chi tiết đặt phòng    [✏️][🗑️] │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Phòng 201 - Phòng Đôi       │    │
│  │ ┌───────────────────────┐   │    │
│  │ │     🛏️ ĐANG Ở          │   │    │
│  │ └───────────────────────┘   │    │
│  └─────────────────────────────┘    │
│                                     │
│  👤 Thông tin khách                │
│  ┌─────────────────────────────┐    │
│  │ Tên: Lê Văn D               │    │
│  │ SĐT: 0901234567             │    │
│  │ CCCD: 001234567890          │    │
│  │ Số khách: 2 người           │    │
│  └─────────────────────────────┘    │
│                                     │
│  📅 Thời gian                      │
│  ┌─────────────────────────────┐    │
│  │ Check-in:  18/01 14:00      │    │
│  │ Check-out: 22/01 12:00      │    │
│  │ Số đêm:    4 đêm            │    │
│  └─────────────────────────────┘    │
│                                     │
│  💰 Thanh toán                     │
│  ┌─────────────────────────────┐    │
│  │ Giá/đêm:   600,000đ         │    │
│  │ Tổng:      2,400,000đ       │    │
│  │ Đặt cọc:   1,200,000đ ✓    │    │
│  │ Còn lại:   1,200,000đ       │    │
│  │                             │    │
│  │ Nguồn: Agoda                │    │
│  │ Mã OTA: AGD-123456          │    │
│  └─────────────────────────────┘    │
│                                     │
│  📝 Ghi chú                        │
│  ┌─────────────────────────────┐    │
│  │ Khách yêu cầu phòng yên     │    │
│  │ tĩnh, tầng 2                │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │     [✓ Check-out ngay]      │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

#### New Booking Screen
```
┌─────────────────────────────────────┐
│  ← Đặt phòng mới          [Lưu ✓] │
├─────────────────────────────────────┤
│                                     │
│  🛏️ Chọn phòng                     │
│  ┌─────────────────────────────┐    │
│  │ [101 🟢] [102 🔴] [103 🔴]  │    │
│  │ [104 🟢] [201 🔴] [202 🟢]  │    │
│  │ [203 🟢]                    │    │
│  │                             │    │
│  │ Đã chọn: 104 - Phòng Đơn   │    │
│  └─────────────────────────────┘    │
│                                     │
│  📅 Thời gian                      │
│  ┌─────────────────────────────┐    │
│  │ Check-in     [19/01/2026 ▼] │    │
│  │ Check-out    [21/01/2026 ▼] │    │
│  │              2 đêm          │    │
│  └─────────────────────────────┘    │
│                                     │
│  👤 Thông tin khách                │
│  ┌─────────────────────────────┐    │
│  │ Tên khách *  [_____________]│    │
│  │ Số điện thoại[_____________]│    │
│  │ Số CCCD      [_____________]│    │
│  │ Số khách     [1 ▼]          │    │
│  └─────────────────────────────┘    │
│                                     │
│  💰 Thanh toán                     │
│  ┌─────────────────────────────┐    │
│  │ Giá/đêm      [500,000    đ] │    │
│  │ Tổng cộng:   1,000,000đ     │    │
│  │                             │    │
│  │ Đặt cọc      [         đ]   │    │
│  │ [x] Đã nhận cọc             │    │
│  │                             │    │
│  │ Nguồn:       [Walk-in    ▼] │    │
│  │ Thanh toán:  [Tiền mặt  ▼]  │    │
│  └─────────────────────────────┘    │
│                                     │
│  📝 Ghi chú                        │
│  ┌─────────────────────────────┐    │
│  │ [                         ] │    │
│  │ [                         ] │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │        [Lưu đặt phòng]      │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

#### Financial Report Screen
```
┌─────────────────────────────────────┐
│  ← Báo cáo tài chính      [📤 Xuất]│
├─────────────────────────────────────┤
│                                     │
│  [Ngày] [Tuần] [*Tháng*] [Năm]     │
│                                     │
│  ◀ Tháng 1, 2026 ▶                 │
│                                     │
│  📊 Tổng quan                      │
│  ┌─────────────────────────────┐    │
│  │      Thu nhập tháng này      │    │
│  │      ┌──────────────┐        │    │
│  │      │ 45,600,000đ  │        │    │
│  │      └──────────────┘        │    │
│  │   ↑ 12% so với tháng trước   │    │
│  └─────────────────────────────┘    │
│                                     │
│  📈 Biểu đồ thu chi                │
│  ┌─────────────────────────────┐    │
│  │     ████                    │    │
│  │  ██ ████ ███                │    │
│  │  ██ ████ ███ ██             │    │
│  │ ─── ──── ─── ──── ...       │    │
│  │  W1   W2   W3   W4          │    │
│  │                             │    │
│  │  ██ Thu   ░░ Chi            │    │
│  └─────────────────────────────┘    │
│                                     │
│  💼 Chi tiết theo loại             │
│                                     │
│  Thu nhập                          │
│  ┌─────────────────────────────┐    │
│  │ 🏨 Tiền phòng   42,000,000đ │    │
│  │ 🍽️ Đồ ăn/uống   2,100,000đ │    │
│  │ ➕ Dịch vụ khác 1,500,000đ  │    │
│  └─────────────────────────────┘    │
│                                     │
│  Chi phí                           │
│  ┌─────────────────────────────┐    │
│  │ ⚡ Tiền điện     3,200,000đ │    │
│  │ 💧 Tiền nước      450,000đ │    │
│  │ 👔 Lương NV      5,000,000đ │    │
│  │ 🧹 Vật tư        2,100,000đ │    │
│  │ 🔧 Bảo trì       1,600,000đ │    │
│  └─────────────────────────────┘    │
│                                     │
│  🏠 Công suất phòng                │
│  ┌─────────────────────────────┐    │
│  │ [██████████░░░░] 72%        │    │
│  │ 158/217 đêm có khách        │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

---

## 7. OTA Integration Strategy

### Phase 4.1: iCal Sync (Simplest)
```
┌─────────────────────────────────────┐
│  Most OTAs support iCal export      │
│  - Import OTA calendars into app    │
│  - Export app calendar to OTAs      │
│  - Manual sync (pull to refresh)    │
└─────────────────────────────────────┘
```

**Pros:** Simple, works with all platforms
**Cons:** Not real-time, manual sync required

### Phase 4.2: Booking.com Integration
```
Channel Manager API:
┌─────────────────────────────────────┐
│  1. Register as Connectivity       │
│     Partner (requires approval)    │
│  2. Implement OTA_HotelAvailNotif  │
│  3. Implement OTA_HotelResNotif    │
│  4. Real-time availability sync    │
│  5. Automatic booking import       │
└─────────────────────────────────────┘
```

**Requirements:**
- Booking.com Connectivity Partner registration
- Technical certification process
- Minimum booking volume requirements

### Phase 4.3: Agoda Integration
```
Agoda YCS (Yield Control System):
┌─────────────────────────────────────┐
│  1. Apply for API access           │
│  2. Implement push/pull sync       │
│  3. Rate and availability updates  │
│  4. Reservation notifications      │
└─────────────────────────────────────┘
```

### Phase 4.4: Airbnb Integration
```
Airbnb API:
┌─────────────────────────────────────┐
│  1. Professional hosting tools     │
│  2. Calendar sync (iCal primary)   │
│  3. Messaging integration          │
│  4. Review management              │
└─────────────────────────────────────┘
```

### Recommended Approach
```
Phase 4 Priority Order:
1. iCal sync first (works immediately)
2. Booking.com API (highest volume)
3. Agoda API (popular in Vietnam)
4. Airbnb API (if needed)
5. Local platforms (Traveloka, etc.)
```

---

## 8. Multi-Currency Support

### Supported Currencies
| Currency | Code | Symbol | Decimal |
|----------|------|--------|---------|
| Vietnamese Dong | VND | ₫ | 0 |
| US Dollar | USD | $ | 2 |
| (Expandable) | ... | ... | ... |

### Exchange Rate Handling
```python
class ExchangeRate(models.Model):
    from_currency = models.CharField(max_length=3)
    to_currency = models.CharField(max_length=3)  # Always VND for reporting
    rate = models.DecimalField(max_digits=15, decimal_places=6)
    date = models.DateField()
    source = models.CharField()  # 'manual', 'api', etc.

# Example: 1 USD = 24,500 VND
# All reports calculated in VND
# Display can toggle between currencies
```

### UI Handling
```
┌─────────────────────────────────────┐
│  Khi nhập thu/chi:                  │
│  ┌─────────────────────────────┐    │
│  │ Số tiền:  [1,000,000      ] │    │
│  │ Đơn vị:   [VND ▼]           │    │
│  │           • VND (₫)         │    │
│  │           • USD ($)         │    │
│  └─────────────────────────────┘    │
│                                     │
│  Nếu chọn USD:                     │
│  ┌─────────────────────────────┐    │
│  │ Số tiền:  [50             ] │    │
│  │ Đơn vị:   [USD ▼]           │    │
│  │ Tỷ giá:   24,500 VND/USD    │    │
│  │ = 1,225,000đ                │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

---

## 9. Security & Privacy

### Authentication & Authorization

#### JWT Token Security
```
┌─────────────────────────────────────────────────────────────┐
│                    Token Management                          │
├─────────────────────────────────────────────────────────────┤
│  Access Token:  Short-lived (15 minutes)                    │
│  Refresh Token: Long-lived (7 days), stored securely        │
│  Token Rotation: New refresh token on each refresh          │
│  Blacklisting:   Revoke tokens on logout/password change    │
└─────────────────────────────────────────────────────────────┘
```

#### Role-Based Access Control (RBAC)
| Role | Permissions |
|------|-------------|
| **Owner** | Full access: all features, settings, user management, financial reports |
| **Manager** | Operational: bookings, check-in/out, daily finance, basic reports |
| **Staff** | Limited: view bookings, housekeeping tasks, room status updates |

### Guest Data Protection

#### Sensitive Data Handling
```python
# Data Classification
SENSITIVE_FIELDS = {
    'HIGH': ['guest_id_number', 'passport_number'],      # CCCD/Passport - encrypted at rest
    'MEDIUM': ['guest_phone', 'guest_email'],            # Contact info - access logged
    'LOW': ['guest_name', 'guest_count'],                # Basic info - standard protection
}

# Encryption Strategy
- Database: AES-256 encryption for HIGH sensitivity fields
- Transit: TLS 1.3 for all API communications
- Storage: Encrypted Hive boxes on mobile (AES)
```

#### Vietnam Data Protection Compliance
| Requirement | Implementation |
|-------------|----------------|
| **CCCD Storage** | Encrypted, access-logged, retention policy (checkout + 30 days) |
| **Guest Consent** | Explicit consent checkbox during booking |
| **Data Retention** | Auto-archive after 1 year, delete after 3 years |
| **Data Export** | Guest can request their data (GDPR-like) |
| **Audit Trail** | Log all access to sensitive guest data |

### API Security

#### Rate Limiting
```
┌─────────────────────────────────────────┐
│  Endpoint Type    │  Rate Limit         │
├───────────────────┼─────────────────────┤
│  Authentication   │  5 requests/minute  │
│  Booking CRUD     │  60 requests/minute │
│  Reports          │  10 requests/minute │
│  General API      │  100 requests/minute│
└───────────────────┴─────────────────────┘
```

#### Security Headers
```python
# Django Security Settings
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True
```

#### Input Validation
- All user inputs sanitized and validated
- SQL injection prevention via Django ORM
- XSS prevention via template escaping
- File upload validation (receipt images only: jpg, png, pdf, max 5MB)

### Mobile App Security

```
┌─────────────────────────────────────────────────────────────┐
│                 Flutter Security Measures                    │
├─────────────────────────────────────────────────────────────┤
│  Secure Storage:  flutter_secure_storage for tokens         │
│  Certificate Pin: Pin SSL certificates (optional)           │
│  Obfuscation:     Code obfuscation for release builds       │
│  Biometric Auth:  Optional fingerprint/face unlock          │
│  Session Timeout: Auto-logout after 30 minutes inactive     │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. Testing Strategy

### Testing Pyramid

```
                    ┌─────────┐
                    │   E2E   │  ← Few, slow, expensive
                    │  Tests  │
                   ─┴─────────┴─
                 ┌───────────────┐
                 │  Integration  │  ← Medium amount
                 │    Tests      │
                ─┴───────────────┴─
              ┌───────────────────────┐
              │      Unit Tests       │  ← Many, fast, cheap
              └───────────────────────┘
```

### Backend Testing (Django)

#### Unit Tests
```python
# Test Categories
tests/
├── test_models/
│   ├── test_room.py           # Room model validation
│   ├── test_booking.py        # Booking business logic
│   └── test_financial.py      # Financial calculations
├── test_api/
│   ├── test_auth.py           # JWT authentication
│   ├── test_bookings.py       # Booking CRUD endpoints
│   ├── test_rooms.py          # Room management
│   └── test_finance.py        # Financial entries
└── test_services/
    ├── test_pricing.py        # Rate calculations
    ├── test_availability.py   # Room availability logic
    └── test_reports.py        # Report generation
```

#### Test Coverage Goals
| Component | Target Coverage |
|-----------|-----------------|
| Models | 90%+ |
| API Views | 85%+ |
| Services/Utils | 90%+ |
| Overall | 80%+ minimum |

#### Testing Tools
```python
# requirements-dev.txt
pytest==8.x
pytest-django==4.x
pytest-cov==4.x
factory-boy==3.x          # Test data factories
faker==22.x               # Fake data generation
responses==0.24.x         # Mock HTTP requests (OTA APIs)
```

### Frontend Testing (Flutter)

#### Unit Tests
```dart
// Test Structure
test/
├── unit/
│   ├── models/            // Data model tests
│   ├── providers/         // Riverpod provider tests
│   └── utils/             // Utility function tests
├── widget/
│   ├── screens/           // Screen widget tests
│   └── components/        // Reusable component tests
└── integration/
    └── flows/             // User flow tests
```

#### Widget Tests
```dart
// Example: Booking Card Widget Test
testWidgets('BookingCard displays guest name and dates', (tester) async {
  final booking = Booking(
    guestName: 'Nguyễn Văn A',
    checkInDate: DateTime(2026, 1, 19),
    checkOutDate: DateTime(2026, 1, 21),
  );

  await tester.pumpWidget(BookingCard(booking: booking));

  expect(find.text('Nguyễn Văn A'), findsOneWidget);
  expect(find.text('19/01 → 21/01'), findsOneWidget);
});
```

#### Testing Tools
```yaml
# pubspec.yaml (dev_dependencies)
flutter_test:
  sdk: flutter
mockito: ^5.4.0
build_runner: ^2.4.0
integration_test:
  sdk: flutter
```

### Integration Testing

#### API Integration Tests
```python
# Test real API flows
class BookingFlowTest(APITestCase):
    def test_complete_booking_flow(self):
        # 1. Login
        # 2. Check room availability
        # 3. Create booking
        # 4. Check-in guest
        # 5. Record payment
        # 6. Check-out guest
        # 7. Verify financial entry created
```

#### Mobile Integration Tests
```dart
// integration_test/booking_flow_test.dart
void main() {
  integrationTest('Complete booking flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login
    await tester.enterText(find.byKey(Key('email')), 'test@hotel.com');
    await tester.enterText(find.byKey(Key('password')), 'password');
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pumpAndSettle();

    // Create booking
    await tester.tap(find.byKey(Key('newBookingFab')));
    // ... continue flow
  });
}
```

### E2E Testing

```
┌─────────────────────────────────────────────────────────────┐
│  Critical User Flows to Test E2E                            │
├─────────────────────────────────────────────────────────────┤
│  1. New user login → view dashboard → create booking        │
│  2. Walk-in guest → booking → check-in → payment → checkout │
│  3. Record expense → view daily summary → monthly report    │
│  4. Offline booking → sync when online → verify data        │
└─────────────────────────────────────────────────────────────┘
```

### Continuous Integration

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Django tests
        run: |
          cd hotel_backend
          pip install -r requirements-dev.txt
          pytest --cov=hotel_api --cov-report=xml

  flutter-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - name: Run Flutter tests
        run: |
          cd hotel_app
          flutter test --coverage
```

---

## 11. Error Handling & Logging

### Backend Error Handling

#### Exception Hierarchy
```python
# hotel_api/exceptions.py
class HotelAPIException(Exception):
    """Base exception for all hotel API errors"""
    status_code = 500
    default_message = "Đã xảy ra lỗi"
    error_code = "INTERNAL_ERROR"

class BookingConflictError(HotelAPIException):
    status_code = 409
    default_message = "Phòng đã được đặt trong thời gian này"
    error_code = "BOOKING_CONFLICT"

class RoomNotAvailableError(HotelAPIException):
    status_code = 400
    default_message = "Phòng không khả dụng"
    error_code = "ROOM_NOT_AVAILABLE"

class PaymentRequiredError(HotelAPIException):
    status_code = 402
    default_message = "Yêu cầu thanh toán trước"
    error_code = "PAYMENT_REQUIRED"
```

#### API Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "BOOKING_CONFLICT",
    "message": "Phòng đã được đặt trong thời gian này",
    "message_en": "Room is already booked for this period",
    "details": {
      "room_id": 101,
      "conflicting_booking_id": 456,
      "requested_dates": "19/01 - 21/01"
    }
  },
  "timestamp": "2026-01-19T10:30:00Z"
}
```

### Frontend Error Handling

#### Error State Management
```dart
// Riverpod error handling pattern
@riverpod
class BookingNotifier extends _$BookingNotifier {
  @override
  AsyncValue<List<Booking>> build() => const AsyncValue.loading();

  Future<void> createBooking(BookingRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(bookingRepositoryProvider).create(request);
    });
  }
}

// UI handles AsyncValue states
booking.when(
  data: (data) => BookingList(bookings: data),
  loading: () => const LoadingSpinner(),
  error: (error, stack) => ErrorWidget(
    message: _getLocalizedError(error),
    onRetry: () => ref.refresh(bookingProvider),
  ),
)
```

#### User-Friendly Error Messages
```dart
// lib/core/errors/error_messages.dart
String getLocalizedError(Object error, String locale) {
  if (error is BookingConflictException) {
    return locale == 'vi'
      ? 'Phòng đã có người đặt. Vui lòng chọn ngày khác.'
      : 'Room already booked. Please select different dates.';
  }
  if (error is NetworkException) {
    return locale == 'vi'
      ? 'Không có kết nối mạng. Đang làm việc offline.'
      : 'No network connection. Working offline.';
  }
  // Default fallback
  return locale == 'vi' ? 'Đã xảy ra lỗi' : 'An error occurred';
}
```

### Logging Strategy

#### Backend Logging
```python
# settings.py
LOGGING = {
    'version': 1,
    'handlers': {
        'console': {'class': 'logging.StreamHandler'},
        'file': {
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/hotel_api.log',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 5,
        },
    },
    'loggers': {
        'hotel_api': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
        },
        'hotel_api.security': {  # Sensitive data access
            'handlers': ['file'],
            'level': 'INFO',
        },
    },
}
```

#### Log Levels & Usage
| Level | Usage | Example |
|-------|-------|---------|
| **ERROR** | Unexpected failures | Database connection failed |
| **WARNING** | Potential issues | Rate limit approaching |
| **INFO** | Business events | Booking created, Check-in completed |
| **DEBUG** | Development details | API request/response payloads |

#### Structured Logging Format
```json
{
  "timestamp": "2026-01-19T10:30:00Z",
  "level": "INFO",
  "logger": "hotel_api.bookings",
  "message": "Booking created",
  "context": {
    "booking_id": 123,
    "room_id": 101,
    "user_id": 1,
    "source": "walk_in"
  },
  "request_id": "abc-123-def"
}
```

#### Mobile Logging
```dart
// Using logger package
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
  ),
);

// Log levels
logger.d('Debug: API request to /bookings');
logger.i('Info: Booking #123 created');
logger.w('Warning: Offline mode, queuing request');
logger.e('Error: Failed to sync', error: e, stackTrace: stack);

// Production: Send errors to crash reporting (Sentry/Crashlytics)
```

---

## 12. Backup & Recovery

### Database Backup Strategy

#### Backup Schedule
```
┌─────────────────────────────────────────────────────────────┐
│                    Backup Schedule                           │
├─────────────────────────────────────────────────────────────┤
│  Frequency     │  Type       │  Retention                   │
├────────────────┼─────────────┼──────────────────────────────┤
│  Every 6 hours │  Incremental│  7 days                      │
│  Daily (2 AM)  │  Full       │  30 days                     │
│  Weekly (Sun)  │  Full       │  3 months                    │
│  Monthly       │  Full       │  1 year                      │
└────────────────┴─────────────┴──────────────────────────────┘
```

#### Backup Implementation
```bash
#!/bin/bash
# scripts/backup.sh

# PostgreSQL backup
BACKUP_DIR="/backups/hotel_db"
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="hotel_backup_${DATE}.sql.gz"

pg_dump hotel_db | gzip > "${BACKUP_DIR}/${FILENAME}"

# Upload to cloud storage (optional)
aws s3 cp "${BACKUP_DIR}/${FILENAME}" s3://hotel-backups/daily/

# Clean old backups (keep last 30 days)
find ${BACKUP_DIR} -name "*.sql.gz" -mtime +30 -delete
```

#### Automated Backup (Cron)
```cron
# /etc/cron.d/hotel_backup
0 2 * * * root /opt/hotel/scripts/backup.sh >> /var/log/hotel_backup.log 2>&1
0 */6 * * * root /opt/hotel/scripts/incremental_backup.sh >> /var/log/hotel_backup.log 2>&1
```

### Recovery Procedures

#### Database Recovery
```bash
# Restore from backup
gunzip -c hotel_backup_20260119.sql.gz | psql hotel_db

# Point-in-time recovery (if WAL archiving enabled)
pg_restore --target-time="2026-01-19 10:00:00" -d hotel_db
```

#### Recovery Time Objectives
| Scenario | RTO (Recovery Time) | RPO (Data Loss) |
|----------|---------------------|-----------------|
| Minor issue | < 1 hour | 0 (no data loss) |
| Database corruption | < 4 hours | < 6 hours |
| Server failure | < 8 hours | < 24 hours |
| Disaster recovery | < 24 hours | < 24 hours |

### Mobile Data Recovery

#### Local Data Backup
```dart
// Hive boxes backup to cloud
Future<void> backupLocalData() async {
  final bookingsBox = Hive.box<Booking>('bookings');
  final financesBox = Hive.box<FinancialEntry>('finances');

  final backup = {
    'bookings': bookingsBox.values.map((b) => b.toJson()).toList(),
    'finances': financesBox.values.map((f) => f.toJson()).toList(),
    'timestamp': DateTime.now().toIso8601String(),
  };

  // Sync to server
  await api.uploadBackup(backup);
}
```

#### Offline Queue Recovery
```
┌─────────────────────────────────────────────────────────────┐
│  Offline Queue Management                                    │
├─────────────────────────────────────────────────────────────┤
│  1. All offline actions stored in pending_operations box    │
│  2. Each operation has unique ID and timestamp              │
│  3. On reconnect, sync in order (oldest first)              │
│  4. Conflict resolution: server wins, notify user           │
│  5. Failed syncs retry 3x, then prompt user                 │
└─────────────────────────────────────────────────────────────┘
```

### Disaster Recovery Plan

```
┌─────────────────────────────────────────────────────────────┐
│                 Disaster Recovery Steps                      │
├─────────────────────────────────────────────────────────────┤
│  1. ASSESS: Identify scope of failure                       │
│  2. NOTIFY: Alert users (mom, brother) of downtime          │
│  3. PROVISION: Spin up new server if needed                 │
│  4. RESTORE: Restore from latest backup                     │
│  5. VERIFY: Test all critical functions                     │
│  6. RESUME: Notify users service is restored                │
│  7. REVIEW: Document incident and improve                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 13. Accessibility Considerations

### Target User Considerations

> **Primary Users:** Mom (50s+) and Brother - may need larger text, simple navigation, and forgiving UI

### Visual Accessibility

#### Font Sizes
```dart
// lib/core/theme/text_theme.dart
class HotelTextTheme {
  // Minimum touch target: 48x48 dp
  // Minimum font size: 16sp for body text

  static const TextTheme lightTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 18),    // Larger than default
    bodyMedium: TextStyle(fontSize: 16),   // Minimum readable
    labelLarge: TextStyle(fontSize: 16),   // Button text
  );
}
```

#### Adjustable Text Size
```dart
// User can increase text size in Settings
class AccessibilitySettings {
  double textScaleFactor;  // 1.0, 1.2, 1.4, 1.6
  bool highContrast;
  bool reducedMotion;
}

// Apply in app
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: settings.textScaleFactor,
      ),
      child: child!,
    );
  },
)
```

#### Color Contrast
```dart
// WCAG AA compliant contrast ratios (4.5:1 minimum)
class HotelColors {
  // Primary actions - high contrast
  static const primary = Color(0xFF1565C0);      // Blue
  static const onPrimary = Color(0xFFFFFFFF);    // White text

  // Status colors - distinguishable
  static const available = Color(0xFF2E7D32);    // Green
  static const occupied = Color(0xFFC62828);     // Red
  static const cleaning = Color(0xFFF9A825);     // Amber

  // Text colors
  static const textPrimary = Color(0xFF212121);  // Dark gray
  static const textSecondary = Color(0xFF616161);// Medium gray

  // Error states
  static const error = Color(0xFFD32F2F);        // Red
  static const errorBackground = Color(0xFFFFEBEE);
}
```

### Touch Accessibility

#### Touch Targets
```dart
// Minimum 48x48 dp touch targets
class HotelButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,  // Larger than minimum for older users
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

// Room status buttons - extra large for easy tapping
class RoomStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,  // Large touch target
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(roomNumber, style: TextStyle(fontSize: 24)),
              Icon(statusIcon, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### Gesture Simplicity
```
┌─────────────────────────────────────────────────────────────┐
│  Gesture Guidelines                                          │
├─────────────────────────────────────────────────────────────┤
│  ✓ Single tap for all primary actions                       │
│  ✓ Avoid swipe-to-delete (use explicit delete button)       │
│  ✓ No complex gestures (pinch, rotate)                      │
│  ✓ Pull-to-refresh with clear visual indicator              │
│  ✓ Long-press only for optional shortcuts                   │
└─────────────────────────────────────────────────────────────┘
```

### Navigation Simplicity

#### Clear Navigation Structure
```
┌─────────────────────────────────────────────────────────────┐
│  Navigation Principles                                       │
├─────────────────────────────────────────────────────────────┤
│  • Maximum 2 levels deep from home                          │
│  • Always visible back button                               │
│  • Clear page titles in Vietnamese                          │
│  • Bottom navigation always accessible                      │
│  • No hidden menus or hamburger menus                       │
└─────────────────────────────────────────────────────────────┘
```

#### Confirmation Dialogs
```dart
// Important actions require confirmation
Future<bool> confirmCheckout(BuildContext context, Booking booking) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Xác nhận trả phòng?', style: TextStyle(fontSize: 20)),
      content: Text(
        'Phòng ${booking.roomNumber} - ${booking.guestName}\n'
        'Bạn có chắc muốn trả phòng?',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          child: Text('Hủy', style: TextStyle(fontSize: 16)),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          child: Text('Xác nhận', style: TextStyle(fontSize: 16)),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}
```

### Feedback & Assistance

#### Clear Feedback
```dart
// Success/error feedback with Vietnamese messages
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(message, style: TextStyle(fontSize: 16)),
        ],
      ),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    ),
  );
}

// Usage
showSuccessSnackbar(context, 'Đã lưu đặt phòng thành công!');
```

#### Help Text
```dart
// Inline help for complex fields
TextFormField(
  decoration: InputDecoration(
    labelText: 'Số CCCD',
    labelStyle: TextStyle(fontSize: 16),
    helperText: 'Nhập 12 số trên căn cước công dân',
    helperStyle: TextStyle(fontSize: 14),
    hintText: '001234567890',
  ),
)
```

### Offline Mode Indicator

```dart
// Clear offline status indicator
class OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'Đang offline - Dữ liệu sẽ đồng bộ khi có mạng',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
```

---

## 14. Development Phases


### Phase 1: Foundation (MVP)
**Duration estimate removed per guidelines - focus on deliverables**

#### Backend Tasks
- [ ] Set up Django project structure
- [ ] Implement User/Auth models and JWT
- [ ] Implement Room and RoomType models
- [ ] Implement Booking model and CRUD API
- [ ] Create seed data for 7 rooms
- [ ] Basic API documentation

#### Frontend Tasks
- [ ] Set up Flutter project structure (copy patterns from cosmo_app)
- [ ] Implement authentication screens
- [ ] Implement Home dashboard
- [ ] Implement Room grid/status view
- [ ] Implement Booking calendar
- [ ] Implement New Booking flow
- [ ] Implement Booking detail/edit
- [ ] Basic offline caching

#### Deliverables
- Working login for 2 users (mom, brother)
- View all 7 rooms with status
- Create/view/edit bookings
- Calendar view of bookings
- Check-in/check-out functionality

---

### Phase 2: Financial Tracking

#### Backend Tasks
- [ ] Implement FinancialCategory model
- [ ] Implement FinancialEntry model
- [ ] API for income/expense CRUD
- [ ] API for financial summaries
- [ ] Multi-currency support

#### Frontend Tasks
- [ ] Finance tab with summary cards
- [ ] Transaction list with filters
- [ ] Add income screen
- [ ] Add expense screen
- [ ] Daily/monthly summary view

#### Deliverables
- Record income (room payments, extras)
- Record expenses (utilities, supplies)
- Daily income/expense summary
- Monthly totals

---

### Phase 3: Reports & Analytics

#### Backend Tasks
- [ ] Revenue report API (by room, by source)
- [ ] Expense report API (by category)
- [ ] Occupancy rate calculation
- [ ] Profit/loss calculation
- [ ] Excel export endpoint

#### Frontend Tasks
- [ ] Financial report screen
- [ ] Charts (bar, line, pie)
- [ ] Occupancy report
- [ ] Export to Excel functionality
- [ ] Date range selection

#### Deliverables
- Monthly/yearly financial reports
- Occupancy rate visualization
- Revenue by room analysis
- Export reports to Excel

---

### Phase 4: OTA Integration

#### Phase 4.1: iCal Sync
- [ ] iCal import/export backend
- [ ] Manual sync UI
- [ ] Conflict detection

#### Phase 4.2: Booking.com (Future)
- [ ] Channel manager registration
- [ ] API implementation
- [ ] Certification testing

#### Phase 4.3: Agoda (Future)
- [ ] YCS API integration
- [ ] Real-time sync

---

### Phase 5: Polish & Production

#### Tasks
- [ ] Push notifications (check-out reminders)
- [ ] Comprehensive testing
- [ ] Performance optimization
- [ ] App store preparation (iOS, Android)
- [ ] Production deployment

---

## 15. Deployment Strategy

### Development Environment
```
Local Development:
├── Flutter: flutter run (iOS Simulator / Android Emulator)
├── Django: python manage.py runserver
└── PostgreSQL: Docker or local installation
```

### Production Environment
```
Option A: Shared with Cosmo (Recommended)
┌─────────────────────────────────────┐
│  Single VPS / Cloud Server          │
│  ├── Nginx (reverse proxy)          │
│  │   ├── /cosmo-api → Django:8000   │
│  │   └── /hotel-api → Django:8001   │
│  ├── PostgreSQL                     │
│  │   ├── cosmo_db                   │
│  │   └── hotel_db                   │
│  └── Redis (shared)                 │
└─────────────────────────────────────┘

Option B: Separate Deployment
┌─────────────────────────────────────┐
│  Dedicated Hotel Server             │
│  ├── Django + Gunicorn              │
│  ├── PostgreSQL                     │
│  └── Nginx                          │
└─────────────────────────────────────┘
```

### Mobile App Distribution
```
iOS:
├── TestFlight (beta testing for mom)
└── App Store (if needed later)

Android:
├── Direct APK (for brother)
├── Google Play Internal Testing
└── Google Play Store (if needed later)
```

---

## Summary & Next Steps

### Recommended Approach
1. **Create new repository**: `hotel-management`
2. **Start with Phase 1**: Core booking functionality
3. **Copy patterns from cosmo_app**: Auth, state management, offline sync
4. **Simple UI**: Focus on ease of use for non-technical users
5. **Vietnamese-first**: Primary language, English optional

### Key Success Metrics
- Mom and brother can create bookings in < 30 seconds
- Financial summary visible on home screen
- Works offline, syncs when connected
- No training needed - intuitive UI

### File Structure to Create
```
hotel-management/           # New repository
├── hotel_app/              # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/           # Copy from cosmo_app
│   │   ├── data/
│   │   └── features/
│   ├── pubspec.yaml
│   └── ...
├── hotel_backend/          # Django backend
│   ├── hotel_api/
│   ├── manage.py
│   └── requirements.txt
├── docs/
├── README.md
└── .gitignore
```

---

**Ready to start building?** Let me know when you'd like to begin Phase 1!
