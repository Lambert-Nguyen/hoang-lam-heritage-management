# Hoang Lam Heritage Management

A mobile-first hotel management application designed for small family-run hotels (7 rooms). Built with Flutter for cross-platform mobile support (iOS + Android) and Django REST Framework for the backend.

## Overview

| Aspect | Details |
|--------|---------|
| **Target Users** | Family members (Mom on iOS, Brother on Android) |
| **Scale** | 7 rooms, small family-run hotel |
| **Languages** | Vietnamese (primary), English (optional) |
| **Offline Support** | Yes - works without internet, syncs when connected |

## Features

### Phase 1: Core MVP (Current)

- **Authentication**: JWT-based login for owner and manager
- **Room Management**: View/edit 7 rooms with status tracking (available, occupied, cleaning, maintenance)
- **Booking Calendar**: Visual calendar showing occupancy
- **Manual Booking**: Create walk-in and phone reservations
- **Check-in/Check-out**: Mark guests as arrived/departed
- **Guest Information**: Name, phone, ID number (CCCD)
- **Dashboard**: Today's overview - rooms, check-ins/outs, revenue

### Phase 2: Financial Tracking

- **Income Recording**: Room revenue, extra services
- **Expense Tracking**: Utilities, supplies, wages
- **Multi-Currency**: VND (primary), USD support with exchange rates
- **Payment Methods**: Cash, bank transfer, MoMo, VNPay
- **Daily/Monthly Summaries**: Revenue, expenses, profit

### Phase 3: Reports & Analytics

- **Revenue Reports**: By room, by source, by month
- **Expense Analysis**: Categorized spending breakdown
- **Occupancy Rate**: Room utilization percentage and trends
- **Export**: Download reports to Excel

### Phase 4: OTA Integration (Future)

- **iCal Sync**: Calendar sync with Airbnb, Booking.com
- **Channel Manager**: Booking.com, Agoda API integration
- **Rate Management**: Sync prices across platforms

### Phase 5: Advanced Features (Future)

- **Housekeeping**: Auto-create cleaning tasks on checkout
- **Minibar/POS**: Sell items, charge to room
- **Guest Communication**: Email confirmations, SMS notifications
- **Push Notifications**: Check-out reminders

## Tech Stack

### Mobile App (Flutter)

| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Flutter 3.x | Cross-platform (iOS + Android) |
| State Management | Riverpod 2.x | Type-safe, testable state |
| HTTP Client | Dio 5.x | API calls with interceptors |
| Local Storage | Hive 2.x | Offline support, encrypted |
| Navigation | GoRouter | Deep linking |
| Models | Freezed + json_serializable | Immutable, type-safe |
| Charts | fl_chart | Financial visualizations |
| Calendar | table_calendar | Booking calendar view |

### Backend (Django)

| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Django 5.x + DRF | REST API |
| Database | PostgreSQL 15+ | Primary data store |
| Authentication | SimpleJWT | Stateless JWT auth |
| Task Queue | Celery + Redis | Background jobs (OTA sync) |
| API Docs | drf-spectacular | OpenAPI/Swagger |

## Project Structure

```
hoang-lam-heritage-management/
├── hotel_app/                    # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                 # Shared utilities, theme, constants
│   │   │   ├── theme/
│   │   │   ├── utils/
│   │   │   └── errors/
│   │   ├── data/                 # Data layer
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   └── features/             # Feature modules
│   │       ├── auth/
│   │       ├── dashboard/
│   │       ├── bookings/
│   │       ├── rooms/
│   │       ├── finance/
│   │       └── settings/
│   ├── test/                     # Tests
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── hotel_backend/                # Django REST API
│   ├── backend/                  # Django project settings
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── hotel_api/                # Main API app
│   │   ├── models/
│   │   ├── views/
│   │   ├── serializers/
│   │   ├── services/
│   │   └── tests/
│   ├── manage.py
│   ├── requirements.txt
│   └── requirements-dev.txt
├── docs/                         # Documentation
├── scripts/                      # Utility scripts (backup, deploy)
├── docker-compose.yml            # Docker setup
└── README.md
```

## Getting Started

### Prerequisites

- **Flutter**: 3.x ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Python**: 3.11+ ([Install Python](https://www.python.org/downloads/))
- **PostgreSQL**: 15+ (or SQLite for development)
- **Docker** (optional): For containerized development

### Backend Setup

#### Option 1: Local Development

```bash
cd hotel_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt  # For testing

# Copy environment file and configure
cp .env.example .env
# Edit .env with your settings (see Environment Variables below)

# Run migrations
python manage.py migrate

# Create superuser (admin account)
python manage.py createsuperuser

# Load seed data (7 rooms, categories)
python manage.py loaddata initial_data

# Run development server
python manage.py runserver
```

#### Option 2: Docker Development

```bash
# Start all services (Django, PostgreSQL, Redis)
docker-compose up -d

# Run migrations
docker-compose exec backend python manage.py migrate

# Create superuser
docker-compose exec backend python manage.py createsuperuser

# View logs
docker-compose logs -f backend
```

### Flutter App Setup

```bash
cd hotel_app

# Get dependencies
flutter pub get

# Generate code (Freezed models, Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>
```

### Environment Variables

Create a `.env` file in `hotel_backend/` with the following:

```env
# Django Settings
DEBUG=True
SECRET_KEY=your-secret-key-here-change-in-production
ALLOWED_HOSTS=localhost,127.0.0.1

# Database (PostgreSQL)
DATABASE_URL=postgres://user:password@localhost:5432/hotel_db
# Or for SQLite (development only):
# DATABASE_URL=sqlite:///db.sqlite3

# JWT Settings
JWT_ACCESS_TOKEN_LIFETIME=15        # minutes
JWT_REFRESH_TOKEN_LIFETIME=10080    # minutes (7 days)

# Redis (for Celery)
REDIS_URL=redis://localhost:6379/0

# Email (optional - for notifications)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
EMAIL_USE_TLS=True

# Sentry (optional - for error tracking)
SENTRY_DSN=

# OTA Integration (Phase 4+)
BOOKING_COM_API_KEY=
AGODA_API_KEY=
```

For the Flutter app, create `hotel_app/lib/core/config/env.dart`:

```dart
class Env {
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  // For production: 'https://your-domain.com/api/v1'
}
```

## API Documentation

When the backend is running:

| Documentation | URL |
|---------------|-----|
| Swagger UI | http://localhost:8000/api/docs/ |
| ReDoc | http://localhost:8000/api/redoc/ |
| OpenAPI Schema | http://localhost:8000/api/schema/ |

### Main API Endpoints

```
Authentication:
  POST   /api/v1/auth/login/          # Login, get tokens
  POST   /api/v1/auth/refresh/        # Refresh access token
  POST   /api/v1/auth/logout/         # Logout, blacklist token

Rooms:
  GET    /api/v1/rooms/               # List all rooms
  GET    /api/v1/rooms/{id}/          # Room details
  PATCH  /api/v1/rooms/{id}/          # Update room status

Bookings:
  GET    /api/v1/bookings/            # List bookings (filterable)
  POST   /api/v1/bookings/            # Create booking
  GET    /api/v1/bookings/{id}/       # Booking details
  PATCH  /api/v1/bookings/{id}/       # Update booking
  DELETE /api/v1/bookings/{id}/       # Cancel booking
  POST   /api/v1/bookings/{id}/checkin/   # Check-in guest
  POST   /api/v1/bookings/{id}/checkout/  # Check-out guest

Finance:
  GET    /api/v1/finance/entries/     # List financial entries
  POST   /api/v1/finance/entries/     # Create entry (income/expense)
  GET    /api/v1/finance/summary/     # Daily/monthly summary
  GET    /api/v1/finance/reports/     # Detailed reports

Dashboard:
  GET    /api/v1/dashboard/           # Today's overview
```

## Testing

### Backend Tests

```bash
cd hotel_backend

# Run all tests
pytest

# Run with coverage
pytest --cov=hotel_api --cov-report=html

# Run specific test file
pytest hotel_api/tests/test_bookings.py

# Run with verbose output
pytest -v
```

### Flutter Tests

```bash
cd hotel_app

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/models/booking_test.dart

# Run integration tests (requires device/emulator)
flutter test integration_test/
```

## Development Workflow

### Git Branch Strategy

```
main              # Production-ready code
├── develop       # Development branch
├── feature/*     # New features (feature/booking-calendar)
├── bugfix/*      # Bug fixes (bugfix/checkout-error)
└── release/*     # Release preparation (release/v1.0.0)
```

### Code Style

**Backend (Python)**:
- Follow PEP 8
- Use `black` for formatting
- Use `isort` for import sorting
- Use `flake8` for linting

```bash
# Format code
black hotel_api/
isort hotel_api/
flake8 hotel_api/
```

**Frontend (Dart)**:
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `dart format` for formatting
- Use `dart analyze` for linting

```bash
# Format code
dart format lib/
dart analyze
```

## Troubleshooting

### Common Issues

#### Backend Issues

**"ModuleNotFoundError: No module named 'xxx'"**
```bash
# Ensure virtual environment is activated
source venv/bin/activate
pip install -r requirements.txt
```

**"django.db.utils.OperationalError: could not connect to server"**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql
# Or start it
sudo systemctl start postgresql
```

**"CORS error" from Flutter app**
```python
# Ensure CORS is configured in settings.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
]
# Or for development:
CORS_ALLOW_ALL_ORIGINS = True  # Don't use in production!
```

#### Flutter Issues

**"Could not find a file named 'pubspec.yaml'"**
```bash
# Ensure you're in the hotel_app directory
cd hotel_app
flutter pub get
```

**"Error: ADB exited with exit code 1"**
```bash
# Restart ADB
adb kill-server
adb start-server
flutter devices
```

**"Null check operator used on a null value"**
```bash
# Regenerate code
flutter pub run build_runner build --delete-conflicting-outputs
```

**Build fails after updating dependencies**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Logs Location

| Service | Log Location |
|---------|--------------|
| Django | `hotel_backend/logs/hotel_api.log` |
| Celery | `hotel_backend/logs/celery.log` |
| Flutter | Device console / `flutter logs` |

## User Roles

| Role | Access Level | Capabilities |
|------|--------------|--------------|
| **Owner** | Full | All features, settings, user management, full financial reports |
| **Manager** | Operational | Bookings, check-in/out, daily finance, basic reports |
| **Staff** | Limited | View bookings, housekeeping tasks, room status updates |

## Deployment

See [HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md](HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md#15-deployment-strategy) for detailed deployment instructions.

### Quick Deploy Checklist

- [ ] Set `DEBUG=False` in production
- [ ] Configure proper `SECRET_KEY`
- [ ] Set up SSL/HTTPS
- [ ] Configure production database
- [ ] Set up database backups
- [ ] Configure email for notifications
- [ ] Build release APK/IPA

## Documentation

- [Design Plan](HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md) - Comprehensive project plan
- [API Documentation](http://localhost:8000/api/docs/) - Interactive API docs (when running)

## Contributing

This is a private project for Hoang Lam Heritage Hotel. For questions or issues, contact the development team.

## License

Private - All rights reserved. Hoang Lam Heritage Hotel.
