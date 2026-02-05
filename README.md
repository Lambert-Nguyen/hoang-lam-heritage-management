# Hoang Lam Heritage Management

<p align="center">
  <strong>🏨 Mobile Hotel Management System for Small Family Hotels</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Backend%20Tests-38%20passing-brightgreen" alt="Backend Tests" />
  <img src="https://img.shields.io/badge/Frontend%20Tests-468%20passing-brightgreen" alt="Frontend Tests" />
  <img src="https://img.shields.io/badge/Python-3.11+-blue" alt="Python" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B" alt="Flutter" />
  <img src="https://img.shields.io/badge/Django-5.x-092E20" alt="Django" />
  <img src="https://img.shields.io/badge/License-Private-red" alt="License" />
</p>

A mobile-first hotel management application designed for small family-run hotels in Vietnam. Built with **Flutter** for cross-platform mobile support (iOS + Android) and **Django REST Framework** for a robust backend API.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Design Patterns](#-design-patterns)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [API Documentation](#-api-documentation)
- [Testing](#-testing)
- [User Roles](#-user-roles)
- [Documentation](#-documentation)
- [License](#-license)

---

## 🏨 Overview

| Aspect | Details |
|--------|---------|
| **Target Users** | Family members (Mom on iOS, Brother on Android) |
| **Scale** | 7 rooms, small family-run hotel |
| **Languages** | Vietnamese (primary), English (optional) |
| **Accessibility** | Large touch targets, adjustable text size for older users |

### Current Status (MVP1 Complete - February 2026)

| Phase | Status | Tests |
|-------|--------|-------|
| **Phase 1: Core MVP** | ✅ Complete | Authentication, Rooms, Bookings, Guests, Dashboard |
| **Phase 2: Financial Tracking** | ✅ Complete | Payments, Deposits, Multi-currency, Receipts |
| **Phase 3: Operations** | ✅ Complete | Housekeeping, Maintenance, Minibar, Inspections |
| **Phase 4: Reports** | ✅ Complete | Occupancy, Revenue, KPI, Demographics |

---

## ✨ Features

### Phase 1: Core MVP ✅
- **Authentication**: JWT-based login with role permissions (owner, manager, staff)
- **Room Management**: View/edit rooms with status tracking (available, occupied, cleaning, maintenance)
- **Booking Calendar**: Visual monthly calendar showing occupancy
- **Manual Booking**: Create walk-in, phone, and hourly reservations
- **Check-in/Check-out**: Mark guests as arrived/departed with timestamps
- **Guest Management**: Full profiles with ID, nationality, VIP tracking
- **Night Audit**: End-of-day summary, close day, statistics
- **Temporary Residence Declaration**: Export guest data for police reporting (CSV/Excel)
- **Dashboard**: Today's overview - rooms, check-ins/outs, revenue

### Phase 2: Financial Tracking ✅
- **Income/Expense Recording**: Categorized financial entries
- **Multi-Currency**: VND, USD with exchange rates
- **Payment Methods**: Cash, bank transfer, MoMo, VNPay, card
- **Deposit Management**: Track partial payments, outstanding balances
- **Receipt Generation**: PDF receipts with currency selection
- **Folio Items**: Track all charges per booking

### Phase 3: Operations & Housekeeping ✅
- **Housekeeping Tasks**: Auto-create cleaning tasks, assignment, completion
- **Maintenance Requests**: Track issues with priority levels and costs
- **Minibar/POS**: Items, sales, charge to room folio
- **Room Inspection**: Checklists with scoring and photo documentation
- **Lost & Found**: Track items with guest claiming workflow
- **Group Booking**: Multiple rooms, single invoice
- **Early/Late Fees**: Automatic fee calculation

### Phase 4: Reports & Analytics ✅
- **Occupancy Reports**: Room utilization trends
- **Revenue Analytics**: By room, source, period
- **KPI Tracking**: RevPAR, ADR calculations
- **Channel Performance**: Revenue by booking source (OTA vs direct)
- **Guest Demographics**: Nationality breakdown
- **Comparative Reports**: Period-over-period analysis
- **Export**: Download to Excel/CSV

---

## 🏗️ Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER MOBILE APP                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │  Screens │ │ Widgets  │ │Providers │ │   Repositories   │   │
│  │   (UI)   │ │  (UI)    │ │ (State)  │ │   (Data Access)  │   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────────┬─────────┘   │
│       │            │            │                 │              │
│       └────────────┴────────────┴─────────────────┘              │
│                            │                                     │
│                     ┌──────┴──────┐                              │
│                     │  Dio HTTP   │ ◄── Interceptors (Auth, Log) │
│                     │   Client    │                              │
│                     └──────┬──────┘                              │
└────────────────────────────┼────────────────────────────────────┘
                             │ HTTPS / REST API
                             │
┌────────────────────────────┼────────────────────────────────────┐
│                     DJANGO REST API                              │
│                     ┌──────┴──────┐                              │
│                     │   Views     │ ◄── ViewSets + Custom Actions│
│                     │ (ViewSets)  │                              │
│                     └──────┬──────┘                              │
│       ┌────────────────────┼────────────────────┐               │
│  ┌────┴────┐          ┌────┴────┐          ┌────┴────┐          │
│  │Serializ.│          │ Models  │          │  Perms  │          │
│  │(Validat)│          │  (ORM)  │          │ (RBAC)  │          │
│  └─────────┘          └────┬────┘          └─────────┘          │
│                            │                                     │
│                     ┌──────┴──────┐                              │
│                     │ PostgreSQL  │                              │
│                     │  Database   │                              │
│                     └─────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
```

### Frontend Architecture (Clean Architecture)

```
lib/
├── core/                 # Cross-cutting concerns
│   ├── config/          # App configuration, constants, endpoints
│   ├── network/         # Dio client, interceptors, error handling
│   ├── theme/           # AppColors, AppSpacing, AppTheme
│   └── utils/           # Helpers, formatters, validators
│
├── models/              # Data Layer - Immutable Freezed models
│   ├── auth.dart        # User, LoginRequest, LoginResponse
│   ├── booking.dart     # Booking, BookingCreate, BookingUpdate
│   ├── guest.dart       # Guest, GuestCreate, GuestHistory
│   ├── room.dart        # Room, RoomType, RoomStatus
│   └── ...              # 15 model files total
│
├── repositories/        # Data Access Layer - API communication
│   ├── auth_repository.dart
│   ├── booking_repository.dart
│   └── ...              # 14 repository files
│
├── providers/           # State Management Layer - Riverpod
│   ├── auth_provider.dart      # AuthNotifier + auth state
│   ├── booking_provider.dart   # Booking list, filters, CRUD
│   └── ...
│
├── screens/             # Presentation Layer - Full pages
│   ├── auth/            # Login, splash screens
│   ├── home/            # Dashboard
│   ├── bookings/        # List, detail, form, calendar
│   ├── rooms/           # Room list, detail, status dialog
│   ├── guests/          # Guest list, detail, form, history
│   └── ...              # 16 screen folders
│
├── widgets/             # Reusable UI Components
│   ├── common/          # AppButton, AppCard, LoadingIndicator
│   ├── bookings/        # BookingCard, StatusBadge, SourceSelector
│   └── ...
│
├── router/              # Navigation
│   └── app_router.dart  # GoRouter with all routes
│
└── main.dart            # App entry point with ProviderScope
```

### Backend Architecture (Django + DRF)

```
hotel_api/
├── models.py            # 15+ Django models with relationships
│   ├── RoomType, Room
│   ├── Guest, Booking
│   ├── FinancialEntry, FinancialCategory, Payment, FolioItem
│   ├── HousekeepingTask, MaintenanceRequest
│   ├── MinibarItem, MinibarSale
│   ├── NightAudit, ExchangeRate
│   ├── LostAndFound, GroupBooking
│   └── RoomInspection, InspectionTemplate
│
├── serializers.py       # DRF serializers for each model
├── views.py             # ViewSets with custom actions
├── urls.py              # Router registration + custom paths
├── permissions.py       # IsOwner, IsManager, IsStaff
│
├── tests/               # Comprehensive test suite
│   ├── test_auth.py
│   ├── test_bookings.py
│   ├── test_guests.py
│   └── ...              # 14 test files
│
├── fixtures/            # Seed data JSON files
└── management/commands/ # Custom Django commands
    ├── seed_room_types.py
    ├── seed_categories.py
    └── create_admin_users.py
```

---

## 🎨 Design Patterns

### Frontend Patterns (Flutter)

| Pattern | Implementation | Purpose |
|---------|---------------|---------|
| **Repository Pattern** | `*_repository.dart` | Abstracts data sources from business logic |
| **Provider Pattern** | Riverpod `StateNotifierProvider` | Reactive, testable state management |
| **Immutable Data** | Freezed `sealed class` | Type-safe models with `copyWith` |
| **Dependency Injection** | Riverpod `ref.read/watch` | Loose coupling, easy testing |
| **Observer Pattern** | `ConsumerWidget`, `ref.watch` | UI reacts to state changes |
| **Factory Pattern** | `fromJson` constructors | JSON deserialization |

#### Example: Repository Pattern
```dart
// Abstract interface
abstract class BookingRepositoryInterface {
  Future<List<Booking>> getBookings({BookingFilter? filter});
  Future<Booking> createBooking(BookingCreate data);
  Future<Booking> checkIn(int id, {String? notes});
}

// Concrete implementation
class BookingRepository implements BookingRepositoryInterface {
  final Dio _dio;
  
  BookingRepository(this._dio);
  
  @override
  Future<List<Booking>> getBookings({BookingFilter? filter}) async {
    final response = await _dio.get(
      AppConstants.bookingsEndpoint,
      queryParameters: filter?.toQueryParams(),
    );
    return (response.data['results'] as List)
        .map((e) => Booking.fromJson(e))
        .toList();
  }
}
```

#### Example: Freezed Immutable Model
```dart
@freezed
sealed class Booking with _$Booking {
  const factory Booking({
    required int id,
    required int room,
    @JsonKey(name: 'room_number') String? roomNumber,
    @JsonKey(name: 'check_in_date') required DateTime checkInDate,
    @JsonKey(name: 'check_out_date') required DateTime checkOutDate,
    @Default(BookingStatus.confirmed) BookingStatus status,
    @JsonKey(name: 'total_amount') @Default(0) double totalAmount,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) => 
      _$BookingFromJson(json);
}
```

#### Example: Riverpod Provider
```dart
@riverpod
class BookingNotifier extends _$BookingNotifier {
  @override
  FutureOr<List<Booking>> build() {
    return ref.read(bookingRepositoryProvider).getBookings();
  }

  Future<void> checkIn(int bookingId) async {
    state = const AsyncLoading();
    try {
      await ref.read(bookingRepositoryProvider).checkIn(bookingId);
      ref.invalidateSelf(); // Refresh list
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
```

### Backend Patterns (Django)

| Pattern | Implementation | Purpose |
|---------|---------------|---------|
| **MVT** | Django default | Model-View-Template separation |
| **ViewSet Pattern** | DRF `ModelViewSet` | RESTful CRUD + custom actions |
| **Serializer Pattern** | DRF Serializers | Validation + transformation |
| **Permission Pattern** | Custom `BasePermission` | Role-based access control |
| **Mixin Pattern** | `@action` decorator | Reusable endpoint behavior |
| **Manager Pattern** | Custom model managers | Query encapsulation |

#### Example: ViewSet with Custom Actions
```python
class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.select_related('room', 'guest').all()
    serializer_class = BookingSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        qs = super().get_queryset()
        if status := self.request.query_params.get('status'):
            qs = qs.filter(status=status)
        return qs
    
    @action(detail=True, methods=['post'])
    def check_in(self, request, pk=None):
        booking = self.get_object()
        if not booking.can_check_in:
            return Response(
                {'error': 'Không thể nhận phòng'},
                status=status.HTTP_400_BAD_REQUEST
            )
        booking.status = Booking.Status.CHECKED_IN
        booking.actual_check_in = timezone.now()
        booking.save()
        return Response(BookingSerializer(booking).data)
    
    @action(detail=False, methods=['get'])
    def calendar(self, request):
        start = request.query_params.get('start_date')
        end = request.query_params.get('end_date')
        bookings = self.get_queryset().filter(
            check_in_date__lte=end,
            check_out_date__gte=start
        )
        return Response(BookingCalendarSerializer(bookings, many=True).data)
```

---

## 🛠️ Tech Stack

### Mobile App (Flutter)

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Framework** | Flutter 3.x | Cross-platform iOS + Android |
| **State Management** | Riverpod 2.x + riverpod_generator | Reactive, type-safe state |
| **Data Models** | Freezed + json_serializable | Immutable models, JSON parsing |
| **HTTP Client** | Dio 5.x | REST API with interceptors |
| **Navigation** | GoRouter | Declarative routing, deep links |
| **Secure Storage** | flutter_secure_storage | Token storage |
| **Charts** | fl_chart | Financial visualizations |
| **Calendar** | table_calendar | Booking calendar view |
| **Internationalization** | flutter_localizations | Vietnamese/English |

### Backend (Django)

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Framework** | Django 5.x + DRF 3.x | REST API framework |
| **Database** | PostgreSQL / SQLite | Data persistence |
| **Authentication** | SimpleJWT | Stateless JWT tokens |
| **PDF Generation** | ReportLab | Receipt/report PDFs |
| **API Documentation** | drf-spectacular | OpenAPI/Swagger |
| **Testing** | pytest-django | Test framework |
| **Code Quality** | black, isort, flake8 | Linting/formatting |

---

## 📁 Project Structure

```
hoang-lam-heritage-management/
│
├── hoang_lam_app/              # 📱 Flutter Mobile Application
│   ├── lib/
│   │   ├── core/               # Configuration, network, theme
│   │   ├── models/             # 15 Freezed model files
│   │   ├── repositories/       # 14 repository files
│   │   ├── providers/          # Riverpod state management
│   │   ├── screens/            # 16 screen folders
│   │   ├── widgets/            # Reusable UI components
│   │   ├── router/             # GoRouter navigation
│   │   └── main.dart
│   ├── test/                   # 468 tests
│   ├── android/                # Android config
│   ├── ios/                    # iOS config
│   └── pubspec.yaml
│
├── hoang_lam_backend/          # 🐍 Django REST API
│   ├── backend/
│   │   ├── settings/           # base, development, production
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── hotel_api/
│   │   ├── models.py           # 15+ database models
│   │   ├── serializers.py      # DRF serializers
│   │   ├── views.py            # ViewSets + API views
│   │   ├── urls.py             # URL routing
│   │   ├── permissions.py
│   │   ├── tests/              # 38 tests
│   │   └── fixtures/
│   ├── manage.py
│   └── requirements.txt
│
├── docs/                       # 📚 Documentation
│   ├── HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md
│   ├── TASKS.md
│   ├── USER_MANUAL.md
│   └── API_REFERENCE.md
│
├── docker-compose.yml          # Local dev stack
├── Makefile                    # Common commands
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter**: 3.x ([Install](https://docs.flutter.dev/get-started/install))
- **Python**: 3.11+ ([Install](https://www.python.org/downloads/))
- **PostgreSQL**: 15+ (or SQLite for development)

### Backend Setup

```bash
cd hoang_lam_backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run migrations
python manage.py migrate

# Seed initial data
python manage.py seed_room_types
python manage.py seed_categories
python manage.py create_admin_users

# Run server
python manage.py runserver
```

### Flutter Setup

```bash
cd hoang_lam_app

# Get dependencies
flutter pub get

# Generate code (Freezed, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run tests
flutter test
```

---

## 📚 API Documentation

### Live Documentation

| Type | URL |
|------|-----|
| Swagger UI | http://localhost:8000/api/docs/ |
| ReDoc | http://localhost:8000/api/redoc/ |
| OpenAPI Schema | http://localhost:8000/api/schema/ |

### Key Endpoints

```
Authentication:
  POST /api/v1/auth/login/           # Login
  POST /api/v1/auth/refresh/         # Refresh token
  POST /api/v1/auth/logout/          # Logout
  GET  /api/v1/auth/me/              # Current user

Rooms:
  GET  /api/v1/rooms/                # List rooms
  GET  /api/v1/rooms/{id}/           # Room detail
  POST /api/v1/rooms/{id}/update_status/  # Update status

Bookings:
  GET  /api/v1/bookings/             # List (with filters)
  POST /api/v1/bookings/             # Create
  GET  /api/v1/bookings/calendar/    # Calendar view
  POST /api/v1/bookings/{id}/check-in/
  POST /api/v1/bookings/{id}/check-out/

Guests:
  GET  /api/v1/guests/               # List
  GET  /api/v1/guests/search/        # Search
  GET  /api/v1/guests/{id}/history/  # Stay history

Reports:
  GET /api/v1/reports/occupancy/
  GET /api/v1/reports/revenue/
  GET /api/v1/reports/kpi/
  GET /api/v1/reports/export/
```

See [API_REFERENCE.md](docs/API_REFERENCE.md) for complete documentation.

---

## 🧪 Testing

### Backend (38 tests)

```bash
cd hoang_lam_backend
source .venv/bin/activate
DJANGO_SETTINGS_MODULE=backend.settings.development \
  python manage.py test hotel_api
```

### Frontend (468 tests)

```bash
cd hoang_lam_app
flutter test
```

---

## 👥 User Roles

| Role | Capabilities |
|------|--------------|
| **Owner** | Full access: settings, users, reports, all features |
| **Manager** | Bookings, check-in/out, finance, basic reports |
| **Staff** | View bookings, update room status |
| **Housekeeping** | Housekeeping tasks, room cleaning status |

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Design Plan](docs/HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md) | Full project specification |
| [Tasks](docs/TASKS.md) | Development task breakdown |
| [User Manual](docs/USER_MANUAL.md) | End-user guide |
| [API Reference](docs/API_REFERENCE.md) | Complete API docs |

---

## 📄 License

**Private** - All rights reserved. Hoang Lam Heritage Hotel © 2026

---

<p align="center">
  Made with ❤️ for Hoang Lam Heritage Hotel
</p>
