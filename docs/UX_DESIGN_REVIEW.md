# UX Design Review — Hoang Lam Heritage Management App

## Review History

- **Round 1** (2026-02-24): Initial review — identified 8 major UX issues
- **Round 1 Implementation**: Fixed 6 issues (role-based nav, collapsible booking form, quick actions, calendar toggle, More menu)
- **Round 2** (2026-02-24): Rigorous re-audit — found 13 remaining issues
- **Round 2 Implementation** (2026-02-24): All 13 issues fixed

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

## Round 2 — Issues FIXED

| # | Severity | Issue | Fix Applied |
|---|----------|-------|-------------|
| 1 | Critical | Folio has no entry point | Added "View Folio" `OutlinedButton` in `booking_detail_screen.dart` when status is `checkedIn` or `checkedOut` — navigates to `/folio/:bookingId` |
| 2 | Critical | Room detail "current booking" dead tap | Connected to `bookingsByRoomProvider` — tapping now navigates to `/bookings/:id` for the active booking. Shows guest name instead of generic text |
| 3 | Critical | Receipt not in checkout flow | Checkout snackbar now shows "View Receipt" action with 5s duration — navigates to `/receipt/:bookingId` |
| 4 | Major | Room dropdown not filtered by availability | Already implemented — `booking_form_screen.dart` uses `availableRoomsProvider(filter)` with date-based `AvailabilityFilter` |
| 5 | Major | MaterialPageRoute → GoRouter migration | All `MaterialPageRoute` usages replaced with `context.push()` across bookings, finance, rooms, tasks, guests, minibar screens. Added new routes: `guestDetail`, `guestForm`, `financeForm`, `minibarItemForm` |
| 6 | Major | Finance month label "Month 2, 2026" | Changed `_getMonthYearText` to use `DateFormat.yMMMM(locale)` — now shows "February 2026" / "Tháng Hai 2026" |
| 7 | Minor | Settings stubs misleading | Added orange "Coming soon" badge (`_buildComingSoonBadge`) on Sync/Backup tiles. Snackbar also shows `featureComingSoon` message |
| 8 | Minor | More menu no category grouping | Restructured with `_MenuSection` class — sections: "Booking Management", "Operations", "Admin & Reports" with headers |
| 9 | Minor | Dashboard placeholder times unlabeled | Added `expectedPrefix` ("Expected:"/"Dự kiến:") before default 14:00/12:00 times |
| 10 | Minor | Room history always "No history" | Connected to `bookingsByRoomProvider` — shows last 5 bookings with status icons, tappable to booking detail |
| 11 | Minor | Guest search overlay stuck after creation | Migrated to GoRouter (`context.push<Guest>(AppRoutes.guestForm)`), overlay removed before push |
| 12 | Minor | Splash screen no feedback after 2s | Added `_showStatusText` bool with 2s `Future.delayed` + `AnimatedOpacity` showing "Checking credentials..." |
| 13 | Minor | Biometric failure blocks manual login | Added `_usernameFocusNode` — after biometric failure, username field auto-focuses for immediate manual entry |

### Files Changed (Round 2)

- `hoang_lam_app/lib/screens/bookings/booking_detail_screen.dart` — View Folio button, receipt after checkout, GoRouter migration
- `hoang_lam_app/lib/screens/rooms/room_detail_screen.dart` — current booking tap, room history, GoRouter migration
- `hoang_lam_app/lib/screens/finance/finance_screen.dart` — month label format, GoRouter migration
- `hoang_lam_app/lib/screens/settings/settings_screen.dart` — coming soon badges, trailing param
- `hoang_lam_app/lib/screens/home/home_screen.dart` — expected prefix on times
- `hoang_lam_app/lib/screens/more/more_menu_screen.dart` — category sections with headers
- `hoang_lam_app/lib/screens/auth/splash_screen.dart` — feedback text after 2s delay
- `hoang_lam_app/lib/screens/auth/login_screen.dart` — username focus after biometric failure
- `hoang_lam_app/lib/widgets/guests/guest_quick_search.dart` — GoRouter migration
- `hoang_lam_app/lib/screens/bookings/bookings_screen.dart` — GoRouter migration
- `hoang_lam_app/lib/screens/bookings/booking_calendar_screen.dart` — GoRouter migration
- `hoang_lam_app/lib/screens/housekeeping/task_list_screen.dart` — GoRouter migration
- `hoang_lam_app/lib/screens/housekeeping/maintenance_list_screen.dart` — GoRouter migration
- `hoang_lam_app/lib/screens/guests/guest_list_screen.dart` — GoRouter migration
- `hoang_lam_app/lib/screens/guests/guest_detail_screen.dart` — GoRouter migration
- `hoang_lam_app/lib/screens/minibar/minibar_inventory_screen.dart` — GoRouter migration
- `hoang_lam_app/lib/screens/rooms/room_management_screen.dart` — GoRouter migration
- `hoang_lam_app/lib/router/app_router.dart` — new routes (guest, finance form, minibar form, booking edit via extra)
- `hoang_lam_app/lib/l10n/app_localizations.dart` — 8 new l10n string pairs for Round 2

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
- **Folio system** — industry-standard charge tracking, accessible from booking detail
- **Role-based bottom nav** — each role sees relevant tabs
- **Quick check-in/out on dashboard** — reduces workflow from 4 taps to 1
- **Collapsible booking form** — walk-in bookings are fast
- **More menu** — all features accessible in 2 taps max
- **Finance summary-first** — monthly totals prominent with drill-down to transactions
- **Guest quick search** — inline search with 300ms debounce, no page navigation needed
