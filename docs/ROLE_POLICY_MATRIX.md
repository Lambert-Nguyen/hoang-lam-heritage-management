# Role-Based Access Control — Canonical Policy Matrix

> **Source of truth** for role enforcement across all 4 layers:
> Menu visibility → Route guards → Backend API permissions → Database-level queries.
>
> **Every new feature** must be added to this document before implementation.
> See [PR Review Checklist](#pr-review-checklist) at the bottom.

---

## Role Hierarchy

| Role | Level | Description |
|------|-------|-------------|
| **owner** | 1 (highest) | Full access — pricing, staff management, finance, all operations |
| **manager** | 2 | Finance, reports, audit — all operations except pricing & staff mgmt |
| **staff** | 3 | Bookings, guests, rooms, operations — no finance/reports |
| **housekeeping** | 4 | Tasks & inspections only — no bookings, no operations |
| **unknown** | 5 (lowest) | Fallback — minimal access, treated as restricted |

---

## Frontend Capabilities (UserRole extension)

| Capability | Owner | Manager | Staff | Housekeeping | Unknown |
|------------|:-----:|:-------:|:-----:|:------------:|:-------:|
| `canViewFinance` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `canEditRates` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `canManageBookings` | ✅ | ✅ | ✅ | ❌ | ✅ |
| `canAccessFullOperations` | ✅ | ✅ | ✅ | ❌ | ❌ |

---

## Backend API Permission Classes

| Class | Allowed Roles | File |
|-------|---------------|------|
| `IsOwner` | owner | `permissions.py` |
| `IsManager` | owner, manager | `permissions.py` |
| `IsStaff` | owner, manager, staff | `permissions.py` |
| `IsHousekeeping` | owner, manager, staff, housekeeping | `permissions.py` |
| `IsOwnerOrManager` | owner, manager (delegates to `IsManager`) | `permissions.py` |
| `IsStaffOrManager` | owner, manager, staff | `permissions.py` |

---

## Complete Role × Endpoint Matrix  (Backend API)

### Authentication & User

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Login | `auth/login/` | ✅ | ✅ | ✅ | ✅ | Public |
| Logout | `auth/logout/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |
| User Profile | `auth/me/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |
| Password Change | `auth/password/change/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |
| Staff List | `auth/staff/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Admin Reset Password | `auth/admin-reset-password/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |

### Dashboard

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Dashboard | `dashboard/` | ✅ | ✅ | ✅ | ❌ | IsStaff |

### Rooms

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Room Types (read) | `room-types/` | ✅ | ✅ | ✅ | ❌ | IsStaff |
| Room Types (write) | `room-types/` | ✅ | ✅ | ❌ | ❌ | IsManager (via get_permissions) |
| Rooms (read) | `rooms/` | ✅ | ✅ | ✅ | ❌ | IsStaff |
| Rooms (write) | `rooms/` | ✅ | ✅ | ❌ | ❌ | IsManager (via get_permissions) |

### Guests

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Guests (read) | `guests/` | ✅ | ✅ | ✅ | ❌ | IsStaff |
| Guests (write) | `guests/` | ✅ | ✅ | ❌ | ❌ | IsManager (via get_permissions) |

### Bookings

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Bookings (all ops) | `bookings/` | ✅ | ✅ | ✅ | ❌ | IsStaff |
| Group Bookings | `group-bookings/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |

### Financial

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Finance Categories (read) | `finance/categories/` | ✅ | ✅ | ✅ | ❌ | IsStaff |
| Finance Categories (write) | `finance/categories/` | ✅ | ✅ | ❌ | ❌ | IsManager (via get_permissions) |
| Finance Entries (read/create) | `finance/entries/` | ✅ | ✅ | ✅ | ❌ | IsStaff |
| Finance Entries (update/delete) | `finance/entries/` | ✅ | ✅ | ❌ | ❌ | IsManager (via get_permissions) |
| Night Audits | `night-audits/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Payments | `payments/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Folio Items | `folio-items/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Exchange Rates (read) | `exchange-rates/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |
| Exchange Rates (write) | `exchange-rates/` | ✅ | ✅ | ❌ | ❌ | IsManager (via get_permissions) |
| Receipts | `receipts/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |

### Operations

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Housekeeping Tasks | `housekeeping-tasks/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Maintenance Requests | `maintenance-requests/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Minibar Items | `minibar-items/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Minibar Sales | `minibar-sales/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Lost & Found | `lost-found/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |

### Inspections

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Inspection Templates | `inspection-templates/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Room Inspections | `room-inspections/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |

### Pricing

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Rate Plans | `rate-plans/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |
| Date Rate Overrides | `date-rate-overrides/` | ✅ | ✅ | ✅ | ❌ | IsStaffOrManager |

### Reports

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Occupancy Report | `reports/occupancy/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |
| Revenue Report | `reports/revenue/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |
| KPI Report | `reports/kpi/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |
| Expense Report | `reports/expenses/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |
| Channel Performance | `reports/channels/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |
| Guest Demographics | `reports/demographics/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |
| Comparative Report | `reports/comparative/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |
| Export Report | `reports/export/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |

### Notifications & Messaging

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Notifications | `notifications/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |
| Device Token | `devices/token/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |
| Notification Prefs | `notifications/preferences/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |
| Message Templates | `message-templates/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |
| Guest Messages | `guest-messages/` | ✅ | ✅ | ✅ | ✅ | IsAuthenticated |

### Audit

| Endpoint | URL Pattern | Owner | Manager | Staff | Housekeeping | Permission |
|----------|-------------|:-----:|:-------:|:-----:|:------------:|------------|
| Audit Logs | `audit-logs/` | ✅ | ✅ | ❌ | ❌ | IsOwnerOrManager |

---

## Complete Role × Route Guard Matrix (Frontend Router)

| Route | Owner | Manager | Staff | Housekeeping | Guard Type |
|-------|:-----:|:-------:|:-----:|:------------:|------------|
| Bookings (list/new/detail/calendar) | ✅ | ✅ | ✅ | ✅ | No guard |
| Guest Form | ✅ | ✅ | ✅ | ❌ | Blocks housekeeping |
| Group Bookings (all) | ✅ | ✅ | ✅ | ❌ | Blocks housekeeping |
| Housekeeping Tasks (all) | ✅ | ✅ | ✅ | ✅ | No guard |
| Room Inspections (all) | ✅ | ✅ | ✅ | ✅ | No guard |
| Maintenance (list/detail/new) | ✅ | ✅ | ✅ | ❌ | Blocks housekeeping |
| Room Detail | ✅ | ✅ | ✅ | ✅ | No guard |
| Room Management (list/new/edit) | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Lost & Found (new/detail/edit) | ✅ | ✅ | ✅ | ❌ | Blocks housekeeping |
| Finance | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Finance Form | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Minibar POS | ✅ | ✅ | ✅ | ❌ | Blocks housekeeping |
| Minibar Inventory | ✅ | ✅ | ✅ | ❌ | Blocks housekeeping |
| Minibar Item Form | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Night Audit | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Declaration | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Reports | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Audit Log | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Financial Categories | ✅ | ✅ | ❌ | ❌ | Owner/Manager only |
| Pricing (all) | ✅ | ❌ | ❌ | ❌ | Owner only |
| Send Message | ✅ | ✅ | ✅ | ❌ | Blocks housekeeping |
| Message History | ✅ | ✅ | ✅ | ❌ | Blocks housekeeping |
| Staff Management | ✅ | ❌ | ❌ | ❌ | Owner only |
| Notifications | ✅ | ✅ | ✅ | ✅ | No guard |
| Settings | ✅ | ✅ | ✅ | ✅ | No guard |

---

## More Menu Visibility Matrix

| Menu Section / Item | Owner | Manager | Staff | Housekeeping | Gate |
|---------------------|:-----:|:-------:|:-----:|:------------:|------|
| **Booking Management** | | | | | `canManageBookings` |
| — Bookings | ✅ | ✅ | ✅ | ❌ | |
| — Group Booking | ✅ | ✅ | ✅ | ❌ | |
| — Guest Management | ✅ | ✅ | ✅ | ❌ | |
| **Operations (base)** | | | | | Always visible |
| — Housekeeping Tasks | ✅ | ✅ | ✅ | ✅ | |
| — Room Inspections | ✅ | ✅ | ✅ | ✅ | |
| **Operations (extended)** | | | | | `canAccessFullOperations` |
| — Maintenance | ✅ | ✅ | ✅ | ❌ | |
| — Room Management | ✅ | ✅ | ✅ | ❌ | |
| — Minibar Management | ✅ | ✅ | ✅ | ❌ | |
| — Lost & Found | ✅ | ✅ | ✅ | ❌ | |
| **Admin & Reports** | | | | | `canViewFinance` |
| — Finance | ✅ | ✅ | ❌ | ❌ | |
| — Night Audit | ✅ | ✅ | ❌ | ❌ | |
| — Reports | ✅ | ✅ | ❌ | ❌ | |
| — Residence Declaration | ✅ | ✅ | ❌ | ❌ | |
| — Audit Log | ✅ | ✅ | ❌ | ❌ | |
| — Pricing | ✅ | ❌ | ❌ | ❌ | `canEditRates` |

---

## PR Review Checklist

Every PR that adds or modifies a feature **must** pass a 4-layer role alignment check:

### 1. Menu Visibility

- [ ] Is the feature visible in the More menu or bottom nav?
- [ ] Is it gated by the correct `UserRole` capability?
- [ ] Does visibility match the intended role scope (see matrices above)?

### 2. Route Guards

- [ ] Does the route have a `redirect:` guard in `app_router.dart`?
- [ ] Does the guard match the backend permission level?
- [ ] For "housekeeping block" routes: `user?.role == UserRole.housekeeping`
- [ ] For "owner/manager only" routes: `user?.role != UserRole.owner && user?.role != UserRole.manager`
- [ ] For "owner only" routes: `user?.role != UserRole.owner`

### 3. Backend API Permissions

- [ ] Does the ViewSet/APIView have explicit `permission_classes`?
- [ ] For read vs. write split: does `get_permissions()` override correctly?
- [ ] Is `IsAuthenticated` always included as the first permission class?
- [ ] Does the permission match the matrices in this document?

### 4. Test Coverage

- [ ] Are there tests in `test_role_authorization.py` for the new endpoint?
- [ ] Do tests verify: allowed roles get non-403, denied roles get 403?
- [ ] Are test users created with correct `HotelUser` profiles?

### 5. Documentation

- [ ] Is this document (`ROLE_POLICY_MATRIX.md`) updated with the new endpoint/route?
- [ ] Are all 4 matrix tables updated (API, Route, Menu, Capabilities)?

---

## Version History

| Date | Change | Author |
|------|--------|--------|
| 2026-03-11 | Initial version — canonical role policy matrix | Role-Based Design Review P2 |
