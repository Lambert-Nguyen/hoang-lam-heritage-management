# UX Design Review — Hoang Lam Heritage Management App

## Review History

- **Round 1** (2026-02-24): Initial review — identified 8 major UX issues
- **Round 1 Implementation**: Fixed 6 issues (role-based nav, collapsible booking form, quick actions, calendar toggle, More menu)
- **Round 2** (2026-02-24): Rigorous re-audit — found 13 remaining issues

---

## Round 1 — Issues FIXED

| # | Issue | Fix Applied |
|---|-------|-------------|
| 1 | Booking form too complex for walk-ins | Optional fields collapsed in `ExpansionTile` — form reduced from 11 to 7 visible fields |
| 2 | Housekeeping/Minibar not in main nav | Added "More" menu screen with role-filtered feature grid |
| 3 | Same nav for all roles | Bottom nav now adapts: Owner gets Finance, Staff gets Housekeeping, Housekeeping gets Tasks+Inspections |
| 4 | Check-in/out requires too many taps | Quick check-in/out buttons added directly on dashboard booking cards |
| 5 | Calendar view hidden | Calendar/list toggle added in bookings AppBar |
| 6 | Features buried in navigation | "More" tab added with grid of all features |

### Files Changed (Round 1)
- `hoang_lam_app/lib/widgets/main_scaffold.dart` — role-based bottom nav
- `hoang_lam_app/lib/screens/more/more_menu_screen.dart` — NEW: feature grid
- `hoang_lam_app/lib/screens/bookings/booking_form_screen.dart` — collapsible optional fields
- `hoang_lam_app/lib/screens/home/home_screen.dart` — quick check-in/out buttons
- `hoang_lam_app/lib/screens/bookings/bookings_screen.dart` — calendar toggle
- `hoang_lam_app/lib/screens/bookings/booking_calendar_screen.dart` — list toggle back
- `hoang_lam_app/lib/router/app_router.dart` — added /more and /booking-calendar routes
- `hoang_lam_app/lib/l10n/app_localizations.dart` — 16 new l10n string pairs

---

## Round 2 — Remaining Issues

### Critical (Workflow Broken)

#### 1. Folio Screen Has No Entry Point
**File**: `hoang_lam_app/lib/screens/bookings/booking_detail_screen.dart`

The room folio screen exists at route `/folio/:bookingId` but **nothing links to it**. Booking detail has no "View Folio" button. A user checking out a guest cannot see itemized charges.

**User impact**: Your sister can't see what a guest owes before checkout. The entire folio system is invisible.

**Fix**: Add "View Folio" button in booking detail screen when status is `checkedIn` or `checkedOut`.

#### 2. Room Detail "Current Booking" is a Dead Tap Target
**File**: `hoang_lam_app/lib/screens/rooms/room_detail_screen.dart`

Shows "This room has guests" + "View booking details" with a chevron arrow, but tapping does nothing. Looks like a real button, is actually a placeholder.

**User impact**: Your mom taps an occupied room, sees "has guests", taps expecting to see who — nothing happens. Erodes trust in the app.

**Fix**: Connect tap handler to navigate to the booking detail for the room's active booking.

#### 3. Receipt Not Connected to Checkout Flow
**File**: `hoang_lam_app/lib/screens/bookings/booking_detail_screen.dart`

`receipt_preview_screen.dart` exists at `/receipt/:bookingId` but the checkout flow never offers "Print Receipt". After checkout, the guest leaves with no bill.

**Fix**: After successful checkout, show a dialog or snackbar action: "View Receipt" → navigate to receipt preview.

### Major (Significant UX Problems)

#### 4. Room Dropdown Not Filtered by Availability
**File**: `hoang_lam_app/lib/screens/bookings/booking_form_screen.dart` (line 153-158)

The room selection dropdown shows ALL rooms regardless of existing bookings. There's a TODO comment acknowledging this. Overlap check only warns AFTER the user has filled the entire form.

**User impact**: Your sister picks Room 101, fills out the whole form, then gets told it's occupied. Wasted effort.

**Fix**: Filter the room dropdown by selected dates using `availableRoomsProvider` or `bookingsByRoomProvider`. Show occupied rooms as disabled/greyed with "(Occupied)" label.

#### 5. Navigation Inconsistency (MaterialPageRoute vs GoRouter)
**Files**: Multiple screens

These screens use `Navigator.push(MaterialPageRoute(...))` instead of GoRouter:
- `bookings_screen.dart` → booking detail (`_navigateToDetail`)
- `bookings_screen.dart` → new booking (`_navigateToCreateBooking`)
- `booking_detail_screen.dart` → edit booking
- `room_detail_screen.dart` → edit room, book room
- `task_list_screen.dart` → task detail, task form

**Impact**: Deep links don't work. Browser back button behavior is inconsistent. State restoration after app kill won't navigate correctly.

**Fix**: Replace all `Navigator.push(MaterialPageRoute(...))` with `context.push(AppRoutes.xxx)`.

#### 6. Finance Month Label Format
**File**: `hoang_lam_app/lib/screens/finance/finance_screen.dart`

Displays "Month 2, 2026" instead of "February 2026" or "Tháng 2, 2026".

**Fix**: Use `DateFormat('MMMM yyyy', locale)` instead of hardcoded "Month X" format.

### Minor (Polish)

#### 7. Settings Has Non-Functional Stubs
**File**: `hoang_lam_app/lib/screens/settings/settings_screen.dart`

"Sync data" and "Backup" tiles look functional but just show snackbars. A non-technical user will believe they backed up their data.

**Fix**: Add "(Coming soon)" badge or disable the tiles.

#### 8. More Menu Has No Category Grouping
**File**: `hoang_lam_app/lib/screens/more/more_menu_screen.dart`

All 13+ feature tiles are in a flat grid with no headers. Hard to scan when looking for a specific feature.

**Fix**: Add section headers: "Booking Management", "Operations", "Admin & Reports".

#### 9. Dashboard Times Show Defaults Without Label
**File**: `hoang_lam_app/lib/screens/home/home_screen.dart`

Upcoming check-in cards show "14:00" and checkout shows "12:00" as placeholder times with no indication these are expected (not actual).

**Fix**: Prefix with "Expected:" or use lighter color/italic for placeholder times.

#### 10. Room Detail History is Placeholder Only
**File**: `hoang_lam_app/lib/screens/rooms/room_detail_screen.dart`

History section always says "No history" — never loads real booking data.

**Fix**: Query `bookingsByRoomProvider` and display recent bookings.

#### 11. Guest Quick Search Overlay Doesn't Auto-Close
**File**: `hoang_lam_app/lib/widgets/guests/guest_quick_search.dart`

After creating a new guest and returning, the autocomplete overlay stays open. User must tap outside manually.

**Fix**: Call `_hideOverlay()` after guest form returns with result.

#### 12. Splash Screen No Feedback After 2 Seconds
**File**: `hoang_lam_app/lib/screens/auth/splash_screen.dart`

If auth check takes >2s on slow network, user sees logo + spinner with no status text. Looks frozen.

**Fix**: After 2s delay, show "Checking credentials..." text below spinner.

#### 13. Biometric Failure Blocks Manual Login
**File**: `hoang_lam_app/lib/screens/auth/login_screen.dart`

When biometric auto-prompts on load and fails, user can't immediately switch to manual login.

**Fix**: After biometric failure, ensure form fields are enabled and focused for immediate password entry.

---

## Priority Matrix

| Priority | # | Issue | Effort |
|----------|---|-------|--------|
| **Critical** | 1 | Folio has no entry point | Small — add button in booking detail |
| **Critical** | 2 | Room detail current booking dead tap | Small — connect to booking route |
| **Critical** | 3 | Receipt not in checkout flow | Small — add post-checkout action |
| **Major** | 4 | Room dropdown not filtered | Medium — wire up availability provider |
| **Major** | 5 | MaterialPageRoute → GoRouter migration | Medium — ~6 screens to update |
| **Major** | 6 | Finance month label format | Small — one DateFormat change |
| **Minor** | 7 | Settings stubs misleading | Small — add badges |
| **Minor** | 8 | More menu no categories | Small — add section headers |
| **Minor** | 9 | Dashboard placeholder times | Small — add "Expected:" prefix |
| **Minor** | 10 | Room history placeholder | Medium — connect provider |
| **Minor** | 11 | Guest search overlay stuck | Small — add hideOverlay call |
| **Minor** | 12 | Splash no feedback text | Small — add delayed text |
| **Minor** | 13 | Biometric blocks manual login | Small — ensure form enabled |

---

## What's Working Well

These design decisions are correct and should be preserved:

- **Vietnamese-first localization** — correct for target audience
- **Biometric login** — reduces friction for daily use
- **Dashboard as home** — occupancy + today's activity is the right first screen
- **Room status color coding** — intuitive at a glance
- **Booking sources** (Walk-in, OTA, Phone) — reflects real hotel operations
- **Payment methods** (MoMo, VNPay, Bank Transfer, Cash) — Vietnamese payment ecosystem
- **Session auto-logout** — good security for shared devices
- **Folio system** — industry-standard charge tracking (just needs to be reachable)
- **Role-based bottom nav** — each role sees relevant tabs
- **Quick check-in/out on dashboard** — reduces workflow from 4 taps to 1
- **Collapsible booking form** — walk-in bookings are fast
- **More menu** — all features accessible in 2 taps max
- **Finance summary-first** — monthly totals prominent with drill-down to transactions
- **Guest quick search** — inline search with 300ms debounce, no page navigation needed
