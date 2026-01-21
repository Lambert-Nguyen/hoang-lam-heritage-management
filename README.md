# Hoang Lam Heritage Management

A mobile-first hotel management application designed for small family-run hotels. Built with Flutter for cross-platform mobile support (iOS + Android) and Django REST Framework for the backend.


## Overview

| Aspect | Details |
| ------ | ------- |
| **Target Users** | Family members (Mom on iOS, Brother on Android) |
| **Scale** | 7 rooms, small family-run hotel |
| **Languages** | Vietnamese (primary), English (optional) |
| **Offline Support** | Yes - works without internet, syncs when connected |
| **Accessibility** | Large touch targets, adjustable text size for older users |

> **Status (2026-01-20):** Folder naming follows `hoang_lam_app/` and `hoang_lam_backend/`. However:
>
> - `pubspec.yaml` still says `hotel_app` (needs rename)
> - Django app is `hotel_api` not `hoang_lam_api` (needs rename)
> - 10 models drafted in `models.py` but no migrations run yet
> - Guest data is embedded in Booking model (needs refactor to separate Guest model)
>
> See [TASKS.md](docs/TASKS.md) for detailed status.

## Documentation

| Document | Description |
| -------- | ----------- |
| [Design Plan](docs/HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md) | Comprehensive project specification |
| [Task Breakdown](docs/TASKS.md) | Detailed tasks for development agents |

## Features by Phase

### Phase 1: Core MVP

- **Authentication**: JWT-based login with role permissions (owner, manager, staff)
- **Room Management**: View/edit 7 rooms with status tracking (available, occupied, cleaning, maintenance)
- **Booking Calendar**: Visual monthly calendar showing occupancy
- **Manual Booking**: Create walk-in, phone, and hourly reservations
- **Check-in/Check-out**: Mark guests as arrived/departed with timestamps
- **Guest Management**: Name, phone, ID/passport, nationality with returning guest detection
- **ID Scanning**: Camera OCR to auto-fill guest info from CCCD/passport 
- **Night Audit**: End-of-day summary, close day, pending payments report
- **Temporary Residence Declaration**: Export guest data for police reporting (Vietnamese legal requirement)
- **Dashboard**: Today's overview - rooms, check-ins/outs, revenue, occupancy %
- **Offline Support**: Works without internet, syncs when connected

### Phase 2: Financial Tracking

- **Income Recording**: Room revenue, extra services, deposits
- **Expense Tracking**: Utilities, supplies, wages, categorized
- **Multi-Currency**: VND (primary), USD with exchange rates
- **Payment Methods**: Cash, bank transfer, MoMo, VNPay, ZaloPay, card
- **Deposit Management**: Track partial payments, outstanding balances
- **Receipt Generation**: PDF receipts with sequential numbering
- **Daily/Monthly Summaries**: Revenue, expenses, profit margins

### Phase 3: Operations & Housekeeping

- **Housekeeping Tasks**: Auto-create cleaning tasks on checkout
- **Task Assignment**: Assign tasks to staff with notifications
- **Maintenance Requests**: Track issues with priority levels
- **Minibar/POS**: Sell items, charge to room folio
- **Room Folio**: Track all charges per booking
- **Early Check-in/Late Check-out**: Handle with automatic fee calculation
- **Hourly Rates**: Support hourly bookings (common in Vietnam)

### Phase 4: Reports & Analytics

- **Occupancy Reports**: Room utilization %, daily/weekly/monthly trends
- **Revenue Analytics**: By room, by source, by period
- **KPI Tracking**: RevPAR, ADR, occupancy rate
- **Channel Performance**: Revenue by booking source
- **Guest Demographics**: Nationality breakdown, repeat guests
- **Export**: Download reports to Excel/CSV

### Phase 5: Guest Communication

- **Booking Confirmations**: Auto-send via SMS/Zalo/email
- **Pre-arrival Messages**: Directions, WiFi info, check-in time
- **Check-out Reminders**: Push notifications
- **Guest Profiles**: Store preferences, stay history
- **Review Requests**: Auto-send after checkout

### Phase 6: OTA Integration (Channel Manager)

- **iCal Sync**: Calendar sync with Airbnb, Booking.com
- **Google Hotel**: Integration with Google Hotel search
- **Rate Management**: Sync prices across platforms
- **Dynamic Pricing**: Auto-adjust rates based on demand
- **Availability Sync**: Real-time inventory across channels
- **Overbooking Prevention**: Real-time sync to prevent double-bookings

### Phase 7: Direct Booking (Booking Engine)

- **Booking Widget**: Embeddable for website/Facebook
- **Online Payments**: VNPay, MoMo integration
- **Promotions**: Discount codes, special offers

### Phase 8: Smart Device Integration (Future)

- **Smart Locks**: Digital door locks, keyless entry
- **Electricity Management**: Auto on/off based on check-in/out
- **Digital Keys**: Mobile app door unlock

## Tech Stack

### Mobile App (Flutter)

| Component | Technology | Purpose |
| --------- | ---------- | ------- |
| Framework | Flutter 3.x | Cross-platform (iOS + Android) |
| State Management | Riverpod 2.x | Type-safe, testable state |
| HTTP Client | Dio 5.x | API calls with interceptors |
| Local Storage | Hive 2.x | Offline support, encrypted |
| Secure Storage | flutter_secure_storage | Token storage |
| Navigation | GoRouter | Deep linking |
| Models | Freezed + json_serializable | Immutable, type-safe |
| Charts | fl_chart | Financial visualizations |
| Calendar | table_calendar | Booking calendar view |
| Camera/OCR | google_mlkit_text_recognition | ID scanning (planned) |
| i18n | flutter_localizations | Vietnamese/English |

### Backend (Django)

| Component | Technology | Purpose |
| --------- | ---------- | ------- |
| Framework | Django 5.x + DRF | REST API |
| Database | PostgreSQL 15+ | Primary data store |
| Authentication | SimpleJWT | Stateless JWT auth |
| Task Queue | Celery + Redis | Background jobs (OTA sync) |
| API Docs | drf-spectacular | OpenAPI/Swagger |
| PDF Generation | (TBD) | Add when receipt/report work begins |

## Project Structure

```
hoang-lam-heritage-management/
├── hoang_lam_app/            # Flutter mobile app (skeleton)
│   └── pubspec.yaml          # ⚠️ Still named "hotel_app" - needs rename
├── hoang_lam_backend/        # Django REST API
│   ├── backend/              # Django project settings
│   └── hotel_api/            # ⚠️ Named "hotel_api" - needs rename to hoang_lam_api
│       ├── models.py         # ✅ 10 models drafted (no migrations yet)
│       ├── views.py          # ❌ Not created
│       └── serializers.py    # ❌ Not created
├── docs/
│   ├── HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md
│   └── TASKS.md
├── docker-compose.yml        # ✅ Local dev (Django/Postgres/Redis)
└── README.md
```

**Next Steps:** Run `makemigrations` + `migrate`, create separate Guest model, then build serializers/views.

## Getting Started

### Prerequisites

- **Flutter**: 3.x ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Python**: 3.11+ ([Install Python](https://www.python.org/downloads/))
- **PostgreSQL**: 15+ (or SQLite for development)
- **Docker** (optional): For containerized development

### Backend Setup

```bash
cd hoang_lam_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Copy environment file and configure
cp .env.example .env
# Edit .env with your settings

# Run migrations
python manage.py migrate

# Create superuser (admin account)
python manage.py createsuperuser

# Load seed data (ships with initial_data.json)
python manage.py loaddata initial_data

# Run development server
python manage.py runserver
```

### Flutter App Setup

```bash
cd hoang_lam_app

# Get dependencies
flutter pub get

# Generate code (Freezed models, Riverpod) after codegen is added
# dart run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run
```

### Environment Variables

Create a `.env` file in `hoang_lam_backend/`:

```env
# Django Settings
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=postgres://user:password@localhost:5432/hoang_lam_db

# JWT Settings
JWT_ACCESS_TOKEN_LIFETIME=15
JWT_REFRESH_TOKEN_LIFETIME=10080

# Redis (for Celery)
REDIS_URL=redis://localhost:6379/0
```

For the Flutter app, once `lib/core/config/` exists, create `hoang_lam_app/lib/core/config/env.dart`:

```dart
class Env {
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
}
```

## API Documentation

When the backend is running:

| Documentation | URL |
| ------------- | --- |
| Swagger UI | http://localhost:8000/api/docs/ |
| ReDoc | http://localhost:8000/api/redoc/ |
| OpenAPI Schema | http://localhost:8000/api/schema/ |

### Main API Endpoints (planned)

Back-end endpoints are not yet implemented; build them following the design plan. Proposed surface:

```
Authentication:
  POST   /api/v1/auth/login/
  POST   /api/v1/auth/refresh/
  POST   /api/v1/auth/logout/
  GET    /api/v1/auth/me/

Rooms:
  GET    /api/v1/rooms/
  GET    /api/v1/rooms/{id}/
  PATCH  /api/v1/rooms/{id}/status/

Bookings:
  GET    /api/v1/bookings/
  POST   /api/v1/bookings/
  POST   /api/v1/bookings/{id}/checkin/
  POST   /api/v1/bookings/{id}/checkout/

Finance (Phase 2):
  GET    /api/v1/finance/entries/
  POST   /api/v1/finance/income/
  POST   /api/v1/finance/expense/

Night Audit (Phase 1 P1):
  GET    /api/v1/night-audit/
  POST   /api/v1/night-audit/close/
```

## Testing

### Backend Tests

Add once test suite exists (expected command: `cd hoang_lam_backend && pytest`).

### Flutter Tests

Add once Flutter tests exist (expected command: `cd hoang_lam_app && flutter test`).

## User Roles

| Role | Access Level | Capabilities |
| ---- | ------------ | ------------ |
| **Owner** | Full | All features, settings, user management, full reports |
| **Manager** | Operational | Bookings, check-in/out, daily finance, basic reports |
| **Staff** | Limited | View bookings, room status updates |
| **Housekeeping** | Tasks only | Housekeeping tasks, room status |

## Development

See [TASKS.md](docs/TASKS.md) for the complete task breakdown with dependencies.

### Git Branch Strategy

```
main              # Production-ready code
├── develop       # Development branch
├── feature/*     # New features
├── bugfix/*      # Bug fixes
└── release/*     # Release preparation
```

### Code Style

**Backend**: `black`, `isort`, `flake8`
**Frontend**: `dart format`, `dart analyze`

## License

Private - All rights reserved. Hoang Lam Heritage Hotel.
