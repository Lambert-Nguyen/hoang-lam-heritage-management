# Hoang Lam Heritage Management

<p align="center">
  <strong>🏨 Mobile Hotel Management System for Small Family Hotels</strong>
</p>

<p align="center">
  <a href="https://github.com/Lambert-Nguyen/hoang-lam-heritage-management/actions/workflows/backend-ci.yml"><img src="https://github.com/Lambert-Nguyen/hoang-lam-heritage-management/actions/workflows/backend-ci.yml/badge.svg" alt="Backend CI" /></a>
  <a href="https://github.com/Lambert-Nguyen/hoang-lam-heritage-management/actions/workflows/flutter-ci.yml"><img src="https://github.com/Lambert-Nguyen/hoang-lam-heritage-management/actions/workflows/flutter-ci.yml/badge.svg" alt="Flutter CI" /></a>
  <a href="https://codecov.io/gh/Lambert-Nguyen/hoang-lam-heritage-management"><img src="https://codecov.io/gh/Lambert-Nguyen/hoang-lam-heritage-management/branch/main/graph/badge.svg" alt="Coverage" /></a>
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

### Current Status (February 2026)

| Phase | Status | Tests |
|-------|--------|-------|
| **Phase 1: Core MVP** | ✅ Complete | Authentication, Rooms, Bookings, Guests, Dashboard |
| **Phase 2: Financial Tracking** | ✅ Complete | Payments, Deposits, Multi-currency, Receipts |
| **Phase 3: Operations** | ✅ Complete | Housekeeping, Maintenance, Minibar, Inspections |
| **Phase 4: Reports** | ✅ Complete | Occupancy, Revenue, KPI, Demographics |
| **Phase 5: Notifications & Messaging** | ✅ Complete | Push Notifications, Guest Messaging, Rate Plans |

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

### Phase 5: Notifications & Messaging ✅

- **Push Notifications**: Firebase-powered alerts for check-ins, check-outs, tasks
- **Notification Preferences**: Per-user notification settings
- **Guest Messaging**: Send messages to guests with templates
- **Message Templates**: Pre-defined templates for common communications
- **Rate Plan Management**: Flexible pricing with date-specific overrides
- **Biometric Authentication**: Fingerprint/Face ID login support
- **Offline Support**: Queue operations for sync when connectivity returns
- **App Settings**: Theme, locale, text size preferences

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
│   ├── storage/         # Hive local persistence
│   ├── services/        # Biometric, connectivity, sync manager
│   ├── errors/          # Error handling
│   └── utils/           # Helpers, formatters, validators
│
├── models/              # Data Layer - Immutable Freezed models
│   ├── auth.dart        # User, LoginRequest, LoginResponse
│   ├── booking.dart     # Booking, BookingCreate, BookingUpdate
│   ├── guest.dart       # Guest, GuestCreate, GuestHistory
│   ├── room.dart        # Room, RoomType, RoomStatus
│   └── ...              # 17 model files total
│
├── repositories/        # Data Access Layer - API communication
│   ├── auth_repository.dart
│   ├── booking_repository.dart
│   └── ...              # 18 repository files
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
│   └── ...              # 19 screen folders
│
├── widgets/             # Reusable UI Components
│   ├── common/          # AppButton, AppCard, LoadingIndicator
│   ├── bookings/        # BookingCard, StatusBadge, SourceSelector
│   └── ...
│
├── router/              # Navigation
│   └── app_router.dart  # GoRouter with all routes
│
├── l10n/                # Internationalization
│   └── app_localizations.dart  # Vietnamese-first localizations
│
└── main.dart            # App entry point with ProviderScope
```

### Backend Architecture (Django + DRF)

```
hotel_api/
├── models.py            # 20+ Django models with relationships
│   ├── RoomType, Room
│   ├── Guest, Booking
│   ├── FinancialEntry, FinancialCategory, Payment, FolioItem
│   ├── HousekeepingTask, MaintenanceRequest
│   ├── MinibarItem, MinibarSale
│   ├── NightAudit, ExchangeRate
│   ├── LostAndFound, GroupBooking
│   ├── RoomInspection, InspectionTemplate
│   ├── RatePlan, DateRateOverride
│   ├── Notification, DeviceToken
│   └── GuestMessage, MessageTemplate
│
├── serializers.py       # DRF serializers for each model
├── views.py             # ViewSets with custom actions
├── urls.py              # Router registration + custom paths
├── permissions.py       # IsOwner, IsManager, IsStaff
├── services.py          # Business logic layer
├── messaging_service.py # Guest messaging service
│
├── tests/               # Comprehensive test suite
│   ├── test_auth.py
│   ├── test_bookings.py
│   ├── test_guests.py
│   └── ...              # 18 test files
│
├── fixtures/            # Seed data JSON files
└── management/commands/ # Custom Django commands
    ├── create_admin_users.py
    ├── seed_room_types.py
    ├── seed_rooms.py
    ├── seed_financial_categories.py
    ├── seed_bookings.py
    ├── seed_guests.py
    ├── seed_nationalities.py
    ├── seed_message_templates.py
    ├── send_checkin_reminders.py
    └── send_checkout_reminders.py
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
| **Biometric** | local_auth | Fingerprint/Face ID login |
| **Offline** | hive + connectivity_plus | Offline queue & sync |
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
| **Push Notifications** | firebase-admin | FCM push notifications |
| **Excel Export** | openpyxl | Report export to Excel |
| **Code Quality** | black, isort, flake8 | Linting/formatting |

---

## 📁 Project Structure

```
hoang-lam-heritage-management/
│
├── hoang_lam_app/              # 📱 Flutter Mobile Application
│   ├── lib/
│   │   ├── core/               # Configuration, network, theme, services
│   │   ├── models/             # 17 Freezed model files
│   │   ├── repositories/       # 18 repository files
│   │   ├── providers/          # 21 Riverpod provider files
│   │   ├── screens/            # 19 screen folders
│   │   ├── widgets/            # Reusable UI components
│   │   ├── router/             # GoRouter navigation
│   │   ├── l10n/               # Internationalization (Vietnamese/English)
│   │   └── main.dart
│   ├── test/                   # 484 tests
│   ├── android/                # Android config
│   ├── ios/                    # iOS config
│   └── pubspec.yaml
│
├── hoang_lam_backend/          # 🐍 Django REST API
│   ├── backend/
│   │   ├── settings/           # base, development, staging, production
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── hotel_api/
│   │   ├── models.py           # 20+ database models
│   │   ├── serializers.py      # DRF serializers
│   │   ├── views.py            # ViewSets + API views
│   │   ├── urls.py             # URL routing
│   │   ├── permissions.py
│   │   ├── services.py         # Business logic
│   │   ├── messaging_service.py # Guest messaging
│   │   ├── tests/              # 38 tests (18 test files)
│   │   ├── fixtures/
│   │   └── management/commands/ # 10 seed/utility commands
│   ├── manage.py
│   └── requirements.txt
│
├── docs/                       # 📚 Documentation (9 files)
│
├── .github/workflows/          # 🔄 CI/CD
│   ├── backend-ci.yml          # Django lint + test + check
│   ├── flutter-ci.yml          # Analyze + test + build (Android/iOS)
│   └── security.yml            # Security scanning
│
├── docker-compose.yml          # Local dev stack (Django + PostgreSQL + Redis)
├── Makefile                    # Common commands (backend, flutter, docker)
├── SECURITY.md                 # Security policies
├── codecov.yml                 # Code coverage config
├── .pre-commit-config.yaml     # Pre-commit hooks
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

# Set Django settings (required for all commands)
export DJANGO_SETTINGS_MODULE=backend.settings.development

# Run migrations
python manage.py migrate

# Seed initial data
python manage.py seed_room_types
python manage.py seed_rooms
python manage.py seed_financial_categories
python manage.py seed_nationalities
python manage.py seed_message_templates
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
  GET /api/v1/reports/expenses/
  GET /api/v1/reports/channels/
  GET /api/v1/reports/demographics/
  GET /api/v1/reports/comparative/
  GET /api/v1/reports/export/

Notifications & Messaging:
  GET  /api/v1/notifications/              # List notifications
  POST /api/v1/devices/token/              # Register device token
  GET  /api/v1/notifications/preferences/  # Notification settings
  GET  /api/v1/message-templates/          # Message templates
  POST /api/v1/guest-messages/             # Send guest message

Rate Plans:
  GET  /api/v1/rate-plans/                 # List pricing plans
  POST /api/v1/date-rate-overrides/        # Date-specific rates
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

### Frontend (484 tests)

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
| [API Reference](docs/API_REFERENCE.md) | Complete API docs |
| [User Manual](docs/USER_MANUAL.md) | End-user guide |
| [Tasks](docs/TASKS.md) | Development task breakdown |
| [Design Gaps Analysis](docs/DESIGN_GAPS_ANALYSIS.md) | Implementation gaps analysis |
| [i18n Implementation](docs/I18N_IMPLEMENTATION.md) | Localization details |
| [Pricing Management](docs/PRICING_MANAGEMENT.md) | Rate plan system |
| [Router Race Condition Fix](docs/ROUTER_RACE_CONDITION_FIX.md) | Navigation issues & solutions |
| [UI Issues Report](docs/UI_ISSUES_REPORT.md) | UI problem tracking |
| [Deployment Guide](docs/DEPLOYMENT.md) | Server setup, env vars, data retention, encryption |
| [Gap Analysis](docs/COMPREHENSIVE_GAP_ANALYSIS_2026_02_13.md) | Comprehensive readiness assessment |

---

## 📄 License

**Private** - All rights reserved. Hoang Lam Heritage Suites © 2026

---

<p align="center">
  Made with ❤️ for Hoang Lam Heritage Suites
</p>
