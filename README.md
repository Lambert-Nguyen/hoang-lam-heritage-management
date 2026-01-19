# Hoang Lam Heritage Management

A hotel management application for small hotels (7 rooms), designed for family-run hospitality businesses.

## Features

### Phase 1: Core MVP
- [x] User authentication (JWT)
- [ ] Room management (7 rooms with status tracking)
- [ ] Booking calendar with visual occupancy
- [ ] Guest check-in/check-out
- [ ] Walk-in and phone reservations

### Phase 2: Financial Tracking
- [ ] Income recording (room revenue, extras)
- [ ] Expense tracking (utilities, supplies, wages)
- [ ] Multi-currency support (VND, USD)
- [ ] Daily/monthly financial summaries

### Phase 3: Reports & Analytics
- [ ] Revenue and expense reports
- [ ] Occupancy rate analytics
- [ ] Export to Excel

### Phase 4: OTA Integration (Future)
- [ ] iCal sync (Airbnb, Booking.com)
- [ ] Booking.com Channel Manager API
- [ ] Agoda API integration

### Phase 5: Advanced Features
- [ ] Housekeeping task management
- [ ] Minibar/POS sales
- [ ] Guest communication (email confirmations)
- [ ] Push notifications

## Tech Stack

### Mobile App (Flutter)
- Flutter 3.x
- Riverpod (state management)
- Dio (HTTP client)
- Hive (local storage, offline support)
- GoRouter (navigation)

### Backend (Django)
- Django 5.x + Django REST Framework
- PostgreSQL
- JWT Authentication (SimpleJWT)
- drf-spectacular (API documentation)

## Project Structure

```
hoang-lam-heritage-management/
├── hotel_app/           # Flutter mobile app (iOS + Android)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── hotel_backend/       # Django REST API
│   ├── backend/         # Django settings
│   ├── hotel_api/       # Main API app
│   ├── manage.py
│   └── requirements.txt
├── docs/                # Documentation
└── README.md
```

## Getting Started

### Prerequisites
- Flutter 3.x
- Python 3.11+
- PostgreSQL 15+ (or SQLite for development)

### Backend Setup

```bash
cd hotel_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env with your settings

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
```

### Flutter App Setup

```bash
cd hotel_app

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

## API Documentation

When the backend is running:
- Swagger UI: http://localhost:8000/api/docs/
- ReDoc: http://localhost:8000/api/redoc/

## Target Users

- **Owner (Mom)**: Full access - booking management, financial reports, settings
- **Manager (Brother)**: Operational access - bookings, check-in/out, daily operations

## License

Private project for Hoang Lam Heritage Hotel.
