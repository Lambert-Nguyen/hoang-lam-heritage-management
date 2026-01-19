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
9. [Development Phases](#9-development-phases)
10. [Deployment Strategy](#10-deployment-strategy)

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

## 9. Development Phases

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

## 10. Deployment Strategy

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
