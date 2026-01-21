# Hoang Lam Heritage Management - Task Breakdown

**Reference:** [Design Plan](./HOANG_LAM_HERITAGE_MANAGEMENT_APP_DESIGN_PLAN.md)
**Inspired by:** [ezCloud Ezhotel](https://ezcloud.vn/san-pham/ezcloudhotel)

> **Code Review (2026-01-20):** Reality check performed. Progress update:
>
> - **✅ Phase 0.1 Complete**: Django backend fully configured with database, settings (dev/staging/production), JWT auth, DRF, CORS, API docs
> - **✅ Migrations Created**: Database schema initialized with all 11 models (RoomType, Room, Guest, Booking, FinancialCategory, FinancialEntry, HotelUser, Housekeeping, MinibarItem, MinibarSale, ExchangeRate)
> - **✅ Guest Model Refactored**: Separate Guest model created with full history tracking, ID image storage, VIP status
> - **⚠️ API Implementation Pending**: Views, serializers, and API endpoints still need to be created (Phase 1)
> - **⚠️ Frontend Setup Pending**: Flutter app needs dependencies added to pubspec.yaml (Phase 0.2)
>
> Tasks below updated with completion status.

## How to Use This File

- **Agents:** Claim tasks by adding your agent ID next to the task
- **Progress:** Mark `[ ]` as `[x]` when complete
- **Dependencies:** Tasks with `[BLOCKED BY: X.X.X]` cannot start until dependency is complete
- **Parallel Work:** Tasks without dependencies can be worked on simultaneously
- **Critical Path:** Phase 0 must complete before Phase 1 begins

---

## Phase 0: Project Setup

> **Note:** All Phase 0 tasks must complete before starting Phase 1

### 0.1 Backend Setup

> **Status**: ✅ PHASE 0.1 COMPLETE - Database initialized, migrations created, settings configured.

- [x] **0.1.1** Create Django project structure (`hoang_lam_backend/`) — ✅ EXISTS
- [x] **0.1.2** Configure PostgreSQL database connection — ✅ DONE (supports SQLite for dev)
- [x] **0.1.3** Set up Django REST Framework — ✅ DONE
- [x] **0.1.4** Configure JWT authentication (SimpleJWT) — ✅ DONE
- [x] **0.1.5** Create base settings (dev, staging, production) — ✅ DONE
- [x] **0.1.6** Set up CORS configuration — ✅ DONE
- [x] **0.1.7** Create custom user model (`HotelUser`) — ✅ DONE
- [x] **0.1.8** Set up logging configuration — ✅ DONE (dev/staging/production)
- [x] **0.1.9** Create API versioning structure (`/api/v1/`) — ✅ DONE
- [x] **0.1.10** Run `makemigrations` and `migrate` to initialize schema — ✅ DONE
- [x] **0.1.11** Create `.env.example` with all required variables — ✅ EXISTS
- [x] **0.1.12** Set up drf-spectacular for API documentation — ✅ DONE
- [ ] **0.1.13** Rename Django app `hotel_api` → `hoang_lam_api` (optional - align with docs)
- [x] **0.1.14** Create `Guest` model (refactor from embedded Booking fields) — ✅ DONE

### 0.2 Frontend Setup

> **Status**: Skeleton project exists. pubspec.yaml needs all dependencies added.

- [x] **0.2.1** Create Flutter project structure (`hoang_lam_app/`) — ✅ EXISTS (skeleton)
- [ ] **0.2.2** Rename app in pubspec.yaml (`hotel_app` → `hoang_lam_app`) ⚠️ **NAMING FIX**
- [ ] **0.2.3** Configure pubspec.yaml with all dependencies (riverpod, dio, hive, go_router, freezed, etc.)
- [ ] **0.2.4** Set up build_runner and code generation (freezed, riverpod_generator) ⚠️ **CRITICAL**
- [ ] **0.2.5** Set up Riverpod for state management
- [ ] **0.2.6** Configure Dio HTTP client with interceptors
- [ ] **0.2.7** Set up Hive for local storage
- [ ] **0.2.8** Configure GoRouter for navigation
- [ ] **0.2.9** Set up Freezed for models
- [ ] **0.2.10** Configure flutter_localizations (vi, en)
- [ ] **0.2.11** Create app theme (colors, typography, spacing)
- [ ] **0.2.12** Set up environment configuration (dev, prod)
- [ ] **0.2.13** Create bottom navigation scaffold
- [ ] **0.2.14** Create base screen template with AppBar
- [ ] **0.2.15** Create common widgets (buttons, cards, inputs)

### 0.3 DevOps Setup

> **Status**: docker-compose exists. CI/CD and linting pending.

- [ ] **0.3.1** Create GitHub Actions for backend tests
- [ ] **0.3.2** Create GitHub Actions for Flutter tests
- [ ] **0.3.3** Set up linting rules (backend - black, isort, flake8)
- [ ] **0.3.4** Set up linting rules (frontend - dart analyze)
- [x] **0.3.5** Create docker-compose for local development — ✅ EXISTS
- [ ] **0.3.6** Create `.gitignore` for both projects (ensure .env not committed)
- [ ] **0.3.7** Set up pre-commit hooks (backend)
- [ ] **0.3.8** Create Makefile for common commands

---

## Phase 1: Core MVP

> **Prerequisite:** Phase 0 must be complete

### 1.1 Authentication (Backend)
`[BLOCKED BY: 0.1.1-0.1.10]`
- [ ] **1.1.1** Create login endpoint (`POST /api/v1/auth/login/`)
- [ ] **1.1.2** Create token refresh endpoint (`POST /api/v1/auth/refresh/`)
- [ ] **1.1.3** Create logout endpoint (`POST /api/v1/auth/logout/`)
- [ ] **1.1.4** Create user profile endpoint (`GET /api/v1/auth/me/`)
- [ ] **1.1.5** Create password change endpoint (`POST /api/v1/auth/password/change/`)
- [ ] **1.1.6** Add role-based permissions (owner, manager, staff, housekeeping)
- [ ] **1.1.7** Create permission decorators for views
- [ ] **1.1.8** Create initial admin user seeder (mom, brother accounts)
- [ ] **1.1.9** Write authentication tests

### 1.2 Authentication (Frontend)
`[BLOCKED BY: 1.1.1-1.1.5, 0.2.1-0.2.10]`
- [ ] **1.2.1** Create login screen UI (Vietnamese-first)
- [ ] **1.2.2** Create auth provider (Riverpod)
- [ ] **1.2.3** Implement secure token storage (flutter_secure_storage)
- [ ] **1.2.4** Create auth interceptor for Dio
- [ ] **1.2.5** Implement auto-logout on token expiry
- [ ] **1.2.6** Create splash screen with auth check
- [ ] **1.2.7** Create biometric authentication option (fingerprint/face)
- [ ] **1.2.8** Create password change screen
- [ ] **1.2.9** Write authentication widget tests

### 1.3 Room Management (Backend)

> **Model Status**: `RoomType` and `Room` DRAFTED in models.py. Needs migration + API.

- [x] **1.3.1** Create `RoomType` model — ✅ DRAFTED (verify fields match Design Plan)
- [x] **1.3.2** Create `Room` model — ✅ DRAFTED (verify fields match Design Plan)
- [ ] **1.3.3** Create RoomType serializer and CRUD endpoints
- [ ] **1.3.4** Create Room serializer and CRUD endpoints
- [ ] **1.3.5** Create room status update endpoint
- [ ] **1.3.6** Create room availability check endpoint
- [ ] **1.3.7** Seed default room types
- [ ] **1.3.8** Seed 7 rooms for Hoang Lam Heritage
- [ ] **1.3.9** Write room management tests

### 1.4 Room Management (Frontend)
`[BLOCKED BY: 1.3.3-1.3.6]`
- [ ] **1.4.1** Create Room model (Freezed)
- [ ] **1.4.2** Create RoomType model (Freezed)
- [ ] **1.4.3** Create room repository
- [ ] **1.4.4** Create room provider (Riverpod)
- [ ] **1.4.5** Create room grid view (dashboard widget)
- [ ] **1.4.6** Create room detail screen
- [ ] **1.4.7** Create room status update dialog
- [ ] **1.4.8** Create room edit screen (admin only)
- [ ] **1.4.9** Add room status color coding
- [ ] **1.4.10** Write room widget tests

### 1.5 Guest Management (Backend)
`[BLOCKED BY: 0.1.14]` _(Guest model refactoring)_

> **Architecture Note**: Guest is currently EMBEDDED in Booking (guest_name, guest_phone, etc.).
> Must refactor to separate `Guest` model per Design Plan for history tracking and VIP status.

- [ ] **1.5.1** Create `Guest` model with all fields (id_type, id_image, nationality, is_vip, total_stays)
- [ ] **1.5.2** Refactor `Booking` model to use ForeignKey to `Guest`
- [ ] **1.5.3** Create Guest serializer and CRUD endpoints
- [ ] **1.5.4** Create guest search endpoint (by name, phone, ID)
- [ ] **1.5.5** Create guest history endpoint
- [ ] **1.5.6** Create returning guest detection logic
- [ ] **1.5.7** Seed nationality list
- [ ] **1.5.8** Seed ID types list
- [ ] **1.5.9** Write guest management tests

### 1.6 Guest Management (Frontend)
`[BLOCKED BY: 1.5.1-1.5.4]`
- [ ] **1.6.1** Create Guest model (Freezed)
- [ ] **1.6.2** Create guest repository
- [ ] **1.6.3** Create guest provider (Riverpod)
- [ ] **1.6.4** Create guest registration form
- [ ] **1.6.5** Create guest search widget
- [ ] **1.6.6** Create guest profile screen
- [ ] **1.6.7** Create guest history view
- [ ] **1.6.8** Implement nationality dropdown
- [ ] **1.6.9** Write guest widget tests

### 1.7 ID Scanning (Frontend)
`[BLOCKED BY: 1.6.4]` _(integrates with guest registration form)_

- [ ] **1.7.1** Integrate camera package (camera, image_picker)
- [ ] **1.7.2** Create ID capture screen with camera preview
- [ ] **1.7.3** Integrate OCR package (google_mlkit_text_recognition)
- [ ] **1.7.4** Create CCCD number parser (12-digit Vietnamese ID)
- [ ] **1.7.5** Create passport parser (MRZ reading)
- [ ] **1.7.6** Auto-fill guest form from OCR results
- [ ] **1.7.7** Store ID image in Hive (encrypted)
- [ ] **1.7.8** Upload ID image to backend on sync
- [ ] **1.7.9** Write ID scanning tests

### 1.8 Booking Management (Backend)
`[BLOCKED BY: 1.3.1-1.3.2, 1.5.1-1.5.2]`

> **Model Status**: `Booking` DRAFTED in models.py. Needs Guest FK refactor + migration + API.

- [x] **1.8.1** Create `Booking` model — ✅ DRAFTED (needs Guest FK after 1.5.2)
- [ ] **1.8.2** Create `GroupBooking` model
- [ ] **1.8.3** Create Booking serializer and CRUD endpoints
- [ ] **1.8.4** Create booking status update endpoint
- [ ] **1.8.5** Create check-in endpoint with timestamp
- [ ] **1.8.6** Create check-out endpoint with timestamp
- [ ] **1.8.7** Create booking calendar endpoint (date range)
- [ ] **1.8.8** Create today's bookings endpoint
- [ ] **1.8.9** Create booking conflict detection
- [ ] **1.8.10** Create booking source list endpoint
- [ ] **1.8.11** Implement hourly booking logic
- [ ] **1.8.12** Implement early check-in / late check-out fees
- [ ] **1.8.13** Write booking management tests

### 1.9 Booking Management (Frontend)
`[BLOCKED BY: 1.8.1-1.8.10, 1.4.1-1.4.4, 1.6.1-1.6.3]`
- [ ] **1.9.1** Create Booking model (Freezed)
- [ ] **1.9.2** Create booking repository
- [ ] **1.9.3** Create booking provider (Riverpod)
- [ ] **1.9.4** Create booking calendar screen (table_calendar)
- [ ] **1.9.5** Create booking list view
- [ ] **1.9.6** Create new booking screen
- [ ] **1.9.7** Create booking detail screen
- [ ] **1.9.8** Create check-in flow
- [ ] **1.9.9** Create check-out flow
- [ ] **1.9.10** Create booking edit screen
- [ ] **1.9.11** Create booking cancellation flow
- [ ] **1.9.12** Create booking source selector
- [ ] **1.9.13** Create hourly booking option
- [ ] **1.9.14** Write booking widget tests

### 1.10 Dashboard (Frontend)
`[BLOCKED BY: 1.4.4, 1.9.3]`
- [ ] **1.10.1** Create dashboard screen layout
- [ ] **1.10.2** Create today's overview widget
- [ ] **1.10.3** Create room status grid widget
- [ ] **1.10.4** Create upcoming check-ins widget
- [ ] **1.10.5** Create upcoming check-outs widget
- [ ] **1.10.6** Create quick stats widget (occupancy %)
- [ ] **1.10.7** Create FAB for new booking
- [ ] **1.10.8** Write dashboard widget tests

### 1.11 Night Audit (Backend)
`[BLOCKED BY: 1.8.1]`
- [ ] **1.11.1** Create `NightAudit` model
- [ ] **1.11.2** Create night audit generation endpoint
- [ ] **1.11.3** Create night audit retrieval endpoint
- [ ] **1.11.4** Create day close endpoint
- [ ] **1.11.5** Calculate daily statistics
- [ ] **1.11.6** Write night audit tests

### 1.12 Night Audit (Frontend)
`[BLOCKED BY: 1.11.1-1.11.4]`
- [ ] **1.12.1** Create NightAudit model (Freezed)
- [ ] **1.12.2** Create night audit provider
- [ ] **1.12.3** Create night audit screen
- [ ] **1.12.4** Create day summary widget
- [ ] **1.12.5** Create pending payments list
- [ ] **1.12.6** Create close day confirmation
- [ ] **1.12.7** Write night audit widget tests

### 1.13 Temporary Residence Declaration (Backend)
`[BLOCKED BY: 1.5.1, 1.8.1]`
- [ ] **1.13.1** Create declaration export endpoint (CSV)
- [ ] **1.13.2** Create declaration export endpoint (Excel)
- [ ] **1.13.3** Create declaration status tracking
- [ ] **1.13.4** Write declaration export tests

### 1.14 Temporary Residence Declaration (Frontend)
`[BLOCKED BY: 1.13.1-1.13.2]`
- [ ] **1.14.1** Create declaration export screen
- [ ] **1.14.2** Create date range selector
- [ ] **1.14.3** Create export format selector
- [ ] **1.14.4** Implement file download/share
- [ ] **1.14.5** Write declaration widget tests

### 1.15 Offline Support (Frontend)
`[BLOCKED BY: 1.4.1-1.4.4, 1.6.1-1.6.3, 1.9.1-1.9.3]`

- [ ] **1.15.1** Create Hive adapters for all models
- [ ] **1.15.2** Create offline booking queue
- [ ] **1.15.3** Create sync manager with retry logic
- [ ] **1.15.4** Create offline indicator widget (banner)
- [ ] **1.15.5** Create sync status widget
- [ ] **1.15.6** Create conflict resolution dialog
- [ ] **1.15.7** Implement background sync on connectivity change
- [ ] **1.15.8** Write offline sync tests

### 1.16 Settings & Profile (Frontend)
`[BLOCKED BY: 1.2.1-1.2.6]`

- [ ] **1.16.1** Create settings screen layout
- [ ] **1.16.2** Create user profile section
- [ ] **1.16.3** Create language selector (vi/en)
- [ ] **1.16.4** Create theme settings (light/dark - future)
- [ ] **1.16.5** Create text size adjustment (accessibility)
- [ ] **1.16.6** Create notification preferences
- [ ] **1.16.7** Create about/version info section
- [ ] **1.16.8** Create logout button with confirmation
- [ ] **1.16.9** Write settings widget tests

### 1.17 Navigation Structure (Frontend)
`[BLOCKED BY: 0.2.6, 0.2.11]`

- [ ] **1.17.1** Implement bottom navigation (Home, Bookings, Finance, Settings)
- [ ] **1.17.2** Configure GoRouter routes for all screens
- [ ] **1.17.3** Implement deep linking support
- [ ] **1.17.4** Create navigation guards (auth check)
- [ ] **1.17.5** Write navigation tests

---

## Phase 2: Financial Tracking

### 2.1 Financial Models (Backend)

> **Model Status**: `FinancialCategory` and `FinancialEntry` DRAFTED. Payment, FolioItem pending.

- [x] **2.1.1** Create `FinancialCategory` model — ✅ DRAFTED
- [x] **2.1.2** Create `FinancialEntry` model — ✅ DRAFTED
- [ ] **2.1.3** Create `Payment` model
- [ ] **2.1.4** Create `FolioItem` model
- [ ] **2.1.5** Seed default expense categories
- [ ] **2.1.6** Seed default income categories
- [ ] **2.1.7** Seed payment methods
- [ ] **2.1.8** Write financial model tests

### 2.2 Financial CRUD (Backend)
`[BLOCKED BY: 2.1.1-2.1.4]`
- [ ] **2.2.1** Create income entry endpoint
- [ ] **2.2.2** Create expense entry endpoint
- [ ] **2.2.3** Create payment recording endpoint
- [ ] **2.2.4** Create folio item endpoint
- [ ] **2.2.5** Create financial entry list endpoint (with filters)
- [ ] **2.2.6** Create daily summary endpoint
- [ ] **2.2.7** Create monthly summary endpoint
- [ ] **2.2.8** Create category list endpoint
- [ ] **2.2.9** Write financial CRUD tests

### 2.3 Financial Management (Frontend)
`[BLOCKED BY: 2.2.1-2.2.8]`
- [ ] **2.3.1** Create FinancialEntry model (Freezed)
- [ ] **2.3.2** Create Payment model (Freezed)
- [ ] **2.3.3** Create finance repository
- [ ] **2.3.4** Create finance provider (Riverpod)
- [ ] **2.3.5** Create finance tab screen
- [ ] **2.3.6** Create transaction list view
- [ ] **2.3.7** Create add income screen
- [ ] **2.3.8** Create add expense screen
- [ ] **2.3.9** Create payment recording screen
- [ ] **2.3.10** Create daily summary widget
- [ ] **2.3.11** Create monthly summary widget
- [ ] **2.3.12** Create category filter
- [ ] **2.3.13** Write finance widget tests

### 2.4 Deposit Management (Backend)
`[BLOCKED BY: 1.8.1, 2.1.3]`
- [ ] **2.4.1** Create deposit recording endpoint
- [ ] **2.4.2** Create deposit status update endpoint
- [ ] **2.4.3** Create outstanding deposits report
- [ ] **2.4.4** Write deposit management tests

### 2.5 Deposit Management (Frontend)
`[BLOCKED BY: 2.4.1-2.4.3]`
- [ ] **2.5.1** Create deposit form (in booking flow)
- [ ] **2.5.2** Create deposit status indicator
- [ ] **2.5.3** Create outstanding deposits list
- [ ] **2.5.4** Write deposit widget tests

### 2.6 Multi-Currency (Backend)

> **Model Status**: `ExchangeRate` DRAFTED in models.py.

- [x] **2.6.1** Create `ExchangeRate` model — ✅ DRAFTED
- [ ] **2.6.2** Create exchange rate serializer and endpoint
- [ ] **2.6.3** Create currency conversion utility
- [ ] **2.6.4** Write currency tests

### 2.7 Multi-Currency (Frontend)
`[BLOCKED BY: 2.6.1-2.6.3]`
- [ ] **2.7.1** Create currency selector widget
- [ ] **2.7.2** Create exchange rate display
- [ ] **2.7.3** Create converted amount display
- [ ] **2.7.4** Write currency widget tests

### 2.8 Receipt Generation (Backend)
`[BLOCKED BY: 1.8.1, 2.1.3]`
- [ ] **2.8.1** Create receipt template
- [ ] **2.8.2** Create receipt generation endpoint (PDF)
- [ ] **2.8.3** Create receipt number sequence
- [ ] **2.8.4** Write receipt generation tests

### 2.9 Receipt Generation (Frontend)
`[BLOCKED BY: 2.8.1-2.8.3]`
- [ ] **2.9.1** Create receipt preview screen
- [ ] **2.9.2** Create receipt share functionality
- [ ] **2.9.3** Create receipt print functionality
- [ ] **2.9.4** Write receipt widget tests

---

## Phase 3: Operations & Housekeeping

### 3.1 Housekeeping Models (Backend)

> **Model Status**: `Housekeeping` DRAFTED (named differently - rename to `HousekeepingTask`). MaintenanceRequest pending.

- [x] **3.1.1** Create `HousekeepingTask` model — ✅ DRAFTED as `Housekeeping` (consider rename)
- [ ] **3.1.2** Create `MaintenanceRequest` model
- [ ] **3.1.3** Seed task types
- [ ] **3.1.4** Seed priority levels
- [ ] **3.1.5** Write housekeeping model tests

### 3.2 Housekeeping CRUD (Backend)
`[BLOCKED BY: 3.1.1-3.1.2]`
- [ ] **3.2.1** Create task CRUD endpoints
- [ ] **3.2.2** Create maintenance request endpoints
- [ ] **3.2.3** Create auto-task creation on checkout
- [ ] **3.2.4** Create task assignment endpoint
- [ ] **3.2.5** Create task completion endpoint
- [ ] **3.2.6** Create task list by room/date
- [ ] **3.2.7** Write housekeeping CRUD tests

### 3.3 Housekeeping (Frontend)
`[BLOCKED BY: 3.2.1-3.2.6]`
- [ ] **3.3.1** Create HousekeepingTask model (Freezed)
- [ ] **3.3.2** Create housekeeping repository
- [ ] **3.3.3** Create housekeeping provider
- [ ] **3.3.4** Create task list screen
- [ ] **3.3.5** Create task detail screen
- [ ] **3.3.6** Create task assignment dialog
- [ ] **3.3.7** Create task completion flow
- [ ] **3.3.8** Create inspection checklist widget
- [ ] **3.3.9** Create photo documentation
- [ ] **3.3.10** Write housekeeping widget tests

### 3.4 Minibar/POS (Backend)
`[BLOCKED BY: 1.8.1, 2.1.4]`

> **Model Status**: `MinibarItem` and `MinibarSale` DRAFTED. RoomMinibar (per-room inventory) pending.

- [x] **3.4.1** Create `MinibarItem` model — ✅ DRAFTED
- [x] **3.4.2** Create `MinibarSale` model — ✅ DRAFTED (charges to booking)
- [ ] **3.4.3** Create `RoomMinibar` model (inventory per room) — if needed
- [ ] **3.4.4** Create minibar serializers and CRUD endpoints
- [ ] **3.4.5** Create charge to room endpoint
- [ ] **3.4.6** Create minibar inventory update
- [ ] **3.4.7** Seed default minibar items
- [ ] **3.4.8** Write minibar tests

### 3.5 Minibar/POS (Frontend)
`[BLOCKED BY: 3.4.1-3.4.5]`
- [ ] **3.5.1** Create MinibarItem model (Freezed)
- [ ] **3.5.2** Create minibar repository
- [ ] **3.5.3** Create minibar provider
- [ ] **3.5.4** Create minibar/POS screen
- [ ] **3.5.5** Create item selector
- [ ] **3.5.6** Create charge confirmation
- [ ] **3.5.7** Create inventory management screen
- [ ] **3.5.8** Write minibar widget tests

### 3.6 Room Folio (Frontend)
`[BLOCKED BY: 3.4.4, 2.3.1-2.3.4]`
- [ ] **3.6.1** Create room folio screen
- [ ] **3.6.2** Create folio item list
- [ ] **3.6.3** Create add charge dialog
- [ ] **3.6.4** Create folio summary
- [ ] **3.6.5** Write folio widget tests

---

## Phase 4: Reports & Analytics

### 4.1 Report Endpoints (Backend)
`[BLOCKED BY: 1.8.1, 2.1.1-2.1.4]`
- [ ] **4.1.1** Create occupancy report endpoint
- [ ] **4.1.2** Create revenue report endpoint
- [ ] **4.1.3** Create RevPAR calculation endpoint
- [ ] **4.1.4** Create ADR calculation endpoint
- [ ] **4.1.5** Create expense report endpoint
- [ ] **4.1.6** Create channel performance endpoint
- [ ] **4.1.7** Create guest demographics endpoint
- [ ] **4.1.8** Create comparative report endpoint
- [ ] **4.1.9** Create Excel export endpoint
- [ ] **4.1.10** Write report tests

### 4.2 Reports (Frontend)
`[BLOCKED BY: 4.1.1-4.1.9]`
- [ ] **4.2.1** Create report screen
- [ ] **4.2.2** Create date range selector
- [ ] **4.2.3** Create occupancy chart (fl_chart)
- [ ] **4.2.4** Create revenue chart
- [ ] **4.2.5** Create expense breakdown chart
- [ ] **4.2.6** Create KPI cards (RevPAR, ADR, Occupancy)
- [ ] **4.2.7** Create channel performance view
- [ ] **4.2.8** Create guest demographics view
- [ ] **4.2.9** Create export functionality
- [ ] **4.2.10** Write report widget tests

---

## Phase 5: Guest Communication

### 5.1 Notifications (Backend)
- [ ] **5.1.1** Set up Firebase Cloud Messaging
- [ ] **5.1.2** Create notification model
- [ ] **5.1.3** Create push notification service
- [ ] **5.1.4** Create booking confirmation notification
- [ ] **5.1.5** Create check-out reminder notification
- [ ] **5.1.6** Create notification preferences endpoint
- [ ] **5.1.7** Write notification tests

### 5.2 Notifications (Frontend)
`[BLOCKED BY: 5.1.1-5.1.6]`
- [ ] **5.2.1** Integrate firebase_messaging
- [ ] **5.2.2** Create notification handler
- [ ] **5.2.3** Create notification settings screen
- [ ] **5.2.4** Create notification list screen
- [ ] **5.2.5** Write notification tests

### 5.3 Guest Messaging (Backend)
- [ ] **5.3.1** Create SMS service integration
- [ ] **5.3.2** Create email service integration
- [ ] **5.3.3** Create Zalo integration (future)
- [ ] **5.3.4** Create message templates
- [ ] **5.3.5** Create message sending endpoint
- [ ] **5.3.6** Write messaging tests

### 5.4 Guest Messaging (Frontend)
`[BLOCKED BY: 5.3.1-5.3.5]`
- [ ] **5.4.1** Create message template selector
- [ ] **5.4.2** Create message preview
- [ ] **5.4.3** Create send confirmation
- [ ] **5.4.4** Write messaging tests

---

## Phase 6: OTA Integration

### 6.1 iCal Sync (Backend)
- [ ] **6.1.1** Create iCal export endpoint
- [ ] **6.1.2** Create iCal import endpoint
- [ ] **6.1.3** Create iCal sync service
- [ ] **6.1.4** Create conflict detection
- [ ] **6.1.5** Write iCal tests

### 6.2 iCal Sync (Frontend)
`[BLOCKED BY: 6.1.1-6.1.4]`
- [ ] **6.2.1** Create OTA settings screen
- [ ] **6.2.2** Create iCal URL display
- [ ] **6.2.3** Create manual sync button
- [ ] **6.2.4** Create sync status display
- [ ] **6.2.5** Write iCal widget tests

### 6.3 Rate Management (Backend)
- [ ] **6.3.1** Create `RatePlan` model
- [ ] **6.3.2** Create `DateRateOverride` model
- [ ] **6.3.3** Create rate plan CRUD endpoints
- [ ] **6.3.4** Create rate override endpoints
- [ ] **6.3.5** Create rate calendar endpoint
- [ ] **6.3.6** Write rate management tests

### 6.4 Rate Management (Frontend)
`[BLOCKED BY: 6.3.1-6.3.5]`
- [ ] **6.4.1** Create RatePlan model (Freezed)
- [ ] **6.4.2** Create rate management screen
- [ ] **6.4.3** Create rate calendar view
- [ ] **6.4.4** Create rate edit dialog
- [ ] **6.4.5** Create bulk rate update
- [ ] **6.4.6** Write rate widget tests

---

## Phase 7: Direct Booking

### 7.1 Booking Widget (Backend)
- [ ] **7.1.1** Create public booking API
- [ ] **7.1.2** Create availability check (public)
- [ ] **7.1.3** Create booking creation (public)
- [ ] **7.1.4** Create payment intent endpoint
- [ ] **7.1.5** Write booking widget tests

### 7.2 Payment Integration (Backend)
- [ ] **7.2.1** Create VNPay integration
- [ ] **7.2.2** Create MoMo integration
- [ ] **7.2.3** Create payment callback handlers
- [ ] **7.2.4** Create payment verification
- [ ] **7.2.5** Write payment integration tests

---

## Phase 8: Smart Device Integration (Future)

### 8.1 Smart Lock Integration
- [ ] **8.1.1** Research smart lock APIs
- [ ] **8.1.2** Create lock integration service
- [ ] **8.1.3** Create digital key generation
- [ ] **8.1.4** Create lock control endpoints
- [ ] **8.1.5** Write lock integration tests

### 8.2 Electricity Management
- [ ] **8.2.1** Research IoT electricity systems
- [ ] **8.2.2** Create electricity control service
- [ ] **8.2.3** Create auto on/off triggers
- [ ] **8.2.4** Write electricity tests

---

## Task Assignment Template

When claiming a task, add your agent ID:

```
- [ ] **1.1.1** Create login endpoint → @agent-backend-1
- [x] **1.1.2** Create token refresh endpoint → @agent-backend-1 ✓
```

## Progress Summary

| Phase | Description | Total Tasks | Completed | Drafted | Pending |
| ----- | ----------- | ----------- | --------- | ------- | ------- |
| 0 | Project Setup | 37 | 16 | 0 | 21 |
| 1 | Core MVP | 97 | 3 | 8 | 86 |
| 2 | Financial Tracking | 32 | 2 | 3 | 27 |
| 3 | Operations & Housekeeping | 30 | 3 | 2 | 25 |
| 4 | Reports & Analytics | 20 | 0 | 0 | 20 |
| 5 | Guest Communication | 17 | 0 | 0 | 17 |
| 6 | OTA Integration | 17 | 0 | 0 | 17 |
| 7 | Direct Booking | 9 | 0 | 0 | 9 |
| 8 | Smart Devices (Future) | 9 | 0 | 0 | 9 |
| **Total** | | **268** | **24** | **13** | **231** |

**Legend:**

- ✅ Completed = Code exists, tested, and verified (e.g., Phase 0.1 backend setup complete with migrations)
- DRAFTED = Model code exists in models.py but API endpoints/views/serializers not yet implemented

**Recent Progress:**
- ✅ Phase 0.1 Complete: Django backend fully configured with database, settings, JWT, DRF, API docs
- ✅ Database initialized with 11 models including refactored Guest model
- 🔨 Next: Phase 0.2 (Frontend Setup) or Phase 1.1 (Authentication APIs)

## Parallel Work Streams

```
Timeline (parallel execution possible):

BACKEND AGENT                    FRONTEND AGENT                  DEVOPS AGENT
─────────────────────────────────────────────────────────────────────────────
Phase 0:
├── 0.1 Backend Setup ──────────►├── 0.2 Frontend Setup ────────►├── 0.3 DevOps
│                                │                                │
Phase 1 (after Phase 0):
├── 1.1 Auth Backend            ├── 1.17 Navigation             │
├── 1.3 Room Backend            │   (can start immediately)     │
├── 1.5 Guest Backend           │                                │
│   ↓                           │   ↓                            │
├── 1.8 Booking Backend ────────►├── 1.2 Auth Frontend           │
├── 1.11 Night Audit Backend    ├── 1.4 Room Frontend           │
├── 1.13 Declaration Backend    ├── 1.6 Guest Frontend          │
│                               ├── 1.7 ID Scanning             │
│                               ├── 1.9 Booking Frontend        │
│                               ├── 1.10 Dashboard              │
│                               ├── 1.12 Night Audit Frontend   │
│                               ├── 1.14 Declaration Frontend   │
│                               ├── 1.15 Offline Support        │
│                               └── 1.16 Settings               │
```

---

**Last Updated:** 2026-01-20 (Phase 0.1 Backend Setup Complete)
