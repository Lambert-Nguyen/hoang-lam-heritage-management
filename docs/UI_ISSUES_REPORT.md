# UI Frontend Issues Report

**Date:** 2026-02-08
**Scope:** Full review of every screen, widget, provider, and interaction in the Flutter frontend
**Total Issues Found:** ~200+

---

## Table of Contents

1. [Critical Issues (7)](#1-critical-issues)
2. [High Severity Issues (30+)](#2-high-severity-issues)
3. [Medium Severity Issues (50+)](#3-medium-severity-issues)
4. [Low Severity Issues (40+)](#4-low-severity-issues)
5. [Cross-Cutting Patterns](#5-cross-cutting-patterns)
6. [Recommended Fix Priority](#6-recommended-fix-priority)

---

## 1. Critical Issues

These are broken core features that either produce incorrect data or are completely non-functional.

### 1.1 Booking Calendar Does Not Refetch on Month Change

- **File:** `lib/screens/bookings/booking_calendar_screen.dart` (lines 166-168)
- **Description:** `onPageChanged` updates `_focusedDay` but never calls `setState()`. When the user swipes to a different month, events for the new month are never loaded from the API. The calendar appears empty for any month other than the initially loaded one.
- **Expected:** Changing months should trigger a data fetch and display bookings for the visible month.
- **Fix:** Add `setState(() { _focusedDay = focusedDay; })` and trigger a provider refresh for the new date range.

### 1.2 Booking Filter Sends camelCase Instead of snake_case to API

- **File:** `lib/providers/booking_provider.dart` (lines 83-84)
- **Description:** `filteredBookingsProvider` uses `status.name` which produces Dart enum names in camelCase (e.g., `checkedIn`) instead of the API's expected snake_case format (e.g., `checked_in`). All status and source filters silently return incorrect or empty results.
- **Expected:** Filters should use `toApiValue` or an equivalent method that produces snake_case strings matching the backend API.
- **Fix:** Replace `status.name` with `status.toApiValue` (or equivalent snake_case mapper) for both status and source query parameters.

### 1.3 Token Refresh Race Condition

- **File:** `lib/core/network/api_interceptors.dart` (lines 46-96)
- **Description:** When multiple API calls receive 401 responses simultaneously, each triggers its own token refresh attempt. The polling-based `_waitForRefresh` mechanism is unreliable — it can miss the completion signal, cause duplicate refresh requests, or leave requests permanently queued.
- **Expected:** Only one refresh should occur at a time; all other 401 responses should wait for the single refresh to complete, then retry with the new token.
- **Fix:** Implement a proper mutex or `Completer<void>` pattern so that the first 401 triggers a refresh and all subsequent ones await the same `Future`.

### 1.4 Report Export Never Saves File

- **File:** `lib/screens/reports/report_screen.dart` (lines 248-276)
- **Description:** The export function calls the repository which returns a `Uint8List` of bytes, but the bytes are never written to disk or shared. The user taps "Export" and nothing visible happens.
- **Expected:** The exported file should be saved to the device's downloads or documents directory, or presented via a share sheet.
- **Fix:** Use `path_provider` to get a writable directory, write the bytes to a file, and either open the file or show a share dialog using `share_plus`.

### 1.5 Hardcoded Mock Staff List in Housekeeping Assignment

- **File:** `lib/widgets/housekeeping/assign_task_dialog.dart` (lines 27-32)
- **Description:** The staff assignment dialog contains a hardcoded list of fake staff members (e.g., "Nguyen Van A", "Tran Thi B") instead of fetching real staff from the API. Any housekeeping task assignment uses fake data.
- **Expected:** The dialog should fetch the actual staff list from the backend API and display real employee names.
- **Fix:** Replace the hardcoded list with a provider that fetches staff from the `/api/users/` or `/api/staff/` endpoint.

### 1.6 Maintenance Assignment is a Stub

- **Files:**
  - `lib/screens/housekeeping/maintenance_list_screen.dart` (lines 333-339)
  - `lib/screens/housekeeping/maintenance_detail_screen.dart` (lines 569-575)
- **Description:** The "Assign" action for maintenance requests contains only a `// TODO: Implement` comment and shows a SnackBar saying the feature is coming soon. The entire maintenance assignment workflow is non-functional.
- **Expected:** Users should be able to assign maintenance tasks to staff members.
- **Fix:** Implement the assignment dialog and API call, or remove the button from the UI if the feature is intentionally deferred.

### 1.7 Minibar Cart Provider Invalidation Bug

- **File:** `lib/providers/minibar_provider.dart` (lines 249-252, 264-271)
- **Description:** `processCart` clears the provider state (sets it to `MinibarState.initial()`) **before** calling `invalidateProviders`. Since `bookingId` is read from the state, it is already `null` by the time invalidation runs, so the dependent providers (booking folio, etc.) are never actually invalidated. The cart state becomes stale after checkout.
- **Expected:** Providers should be invalidated using the `bookingId` before the state is cleared.
- **Fix:** Capture `bookingId` in a local variable before clearing state, then pass it to `invalidateProviders`.

---

## 2. High Severity Issues

These are broken interactions, data integrity problems, or crashes that users will encounter during normal usage.

### 2.1 Authentication

#### 2.1.1 Biometric Dialog Navigates Away Immediately

- **File:** `lib/screens/auth/login_screen.dart` (lines 104-118)
- **Description:** After showing the biometric authentication dialog, the code immediately navigates to the home screen without waiting for the dialog result. The user sees the dialog flash briefly and disappear.
- **Fix:** Await the biometric authentication result before navigating.

#### 2.1.2 Biometric Login Doesn't Re-authenticate with Server

- **File:** `lib/screens/auth/login_screen.dart` (lines 66-74)
- **Description:** Biometric login retrieves the cached JWT token and uses it directly without verifying it's still valid on the server. If the token has expired, the user appears logged in but all API calls fail.
- **Fix:** After biometric verification, validate the token with the server or perform a silent refresh.

#### 2.1.3 Splash Screen Has No Timeout Fallback

- **File:** `lib/screens/auth/splash_screen.dart`
- **Description:** The splash screen waits indefinitely for the auth check to complete. On a slow or offline network, the app can hang on the splash screen forever.
- **Fix:** Add a timeout (e.g., 10 seconds) that falls back to the login screen.

#### 2.1.4 Password Change Swallows Server Error Details

- **File:** `lib/screens/auth/password_change_screen.dart`
- **Description:** When the password change API returns an error, only a generic error message is shown. The actual server response (e.g., "password too common", "too similar to username") is discarded.
- **Fix:** Parse and display the server's error message to the user.

#### 2.1.5 Auth Provider Timer Race Condition

- **File:** `lib/providers/auth_provider.dart` (lines 233-235)
- **Description:** The token refresh timer may fire after the provider has been disposed, causing a state-after-dispose error.
- **Fix:** Cancel the timer in the `dispose` method and check `mounted` before setting state.

### 2.2 Dashboard

#### 2.2.1 Pull-to-Refresh Doesn't Work

- **File:** `lib/screens/home/home_screen.dart`
- **Description:** `RefreshIndicator` wraps a non-scrollable child widget. The pull gesture is never detected, and even if triggered programmatically, the refresh completes instantly without waiting for data.
- **Fix:** Wrap the content in a `SingleChildScrollView` with `AlwaysScrollableScrollPhysics`, and await the actual data fetch in the `onRefresh` callback.

#### 2.2.2 Notifications Button is a Dead Tap

- **File:** `lib/screens/home/home_screen.dart` (lines 36-39)
- **Description:** The notifications bell icon in the AppBar has an `onPressed` handler that does nothing.
- **Fix:** Either implement the notifications screen or remove the button.

#### 2.2.3 Room Status Legend Colors Don't Match Room Cards

- **File:** `lib/widgets/dashboard/dashboard_occupancy_widget.dart`
- **Description:** The color legend for room statuses uses different color values than the actual room status cards, making the legend misleading.
- **Fix:** Extract room status colors into a shared constant/theme and use them consistently.

#### 2.2.4 Room Status Changes Don't Update Dashboard Stats

- **Description:** When a room status is changed via the long-press action on the dashboard, the occupancy counts and statistics are not refreshed because the relevant providers are not invalidated.
- **Fix:** Invalidate `dashboardProvider` and `roomStatusCountsProvider` after a room status update.

#### 2.2.5 Static Date Header Never Updates at Midnight

- **File:** `lib/screens/home/home_screen.dart`
- **Description:** The date displayed in the header is computed once at build time and never refreshed. If the app is left open overnight, it shows yesterday's date.
- **Fix:** Use a timer or listen to app lifecycle events to refresh the date.

### 2.3 Room Management

#### 2.3.1 Detail Screen Shows Stale Data After Dialog Update

- **File:** `lib/screens/rooms/room_detail_screen.dart` (lines 35-41)
- **Description:** The detail screen copies the room object into local state. After updating the room status via a dialog, the local copy is not refreshed, so the screen continues showing the old status.
- **Fix:** Re-read the room from the provider after a successful update, or make the screen reactive to the provider's state.

#### 2.3.2 SnackBar Shown After Navigator.pop on Invalid Context

- **File:** `lib/widgets/rooms/room_status_dialog.dart` (lines 223-231)
- **Description:** After updating a room's status, the dialog pops itself and then tries to show a SnackBar using the now-invalid context. This can cause a crash or a silently swallowed error.
- **Fix:** Show the SnackBar before popping, or pass the result back to the parent screen and let it show the SnackBar.

#### 2.3.3 No Status Transition Validation

- **File:** `lib/widgets/rooms/room_status_dialog.dart`
- **Description:** Any room status can be changed to any other status without validation. Invalid transitions (e.g., "Occupied" directly to "Available" without checkout) are allowed.
- **Fix:** Add transition rules that only allow valid status changes.

#### 2.3.4 Inactive Rooms Tab Never Shows Data

- **File:** `lib/providers/room_provider.dart` (lines 21-24)
- **Description:** `roomsProvider` hardcodes `isActive: true` in the API query. The "Inactive" tab on the room management screen always shows an empty list.
- **Fix:** Create a separate provider or parameterize the existing one to accept an `isActive` filter.

#### 2.3.5 Search Clear Button Doesn't Clear TextField

- **File:** `lib/screens/rooms/room_management_screen.dart`
- **Description:** The clear (X) button on the search bar clears the filter state but does not clear the `TextField`'s visible text because there is no `TextEditingController` linked to it.
- **Fix:** Add a `TextEditingController` and call `.clear()` on it when the clear button is pressed.

#### 2.3.6 Edit Button is a No-Op

- **File:** `lib/screens/rooms/room_detail_screen.dart` (lines 49-55)
- **Description:** The edit button in the room detail AppBar contains only a `// TODO` comment and does nothing when tapped.
- **Fix:** Implement the edit flow or remove the button.

#### 2.3.7 Room Creation Sends `id: 0` to Backend

- **Description:** When creating a new room, the model is initialized with `id: 0`. This is sent to the backend, which may reject it or cause conflicts.
- **Fix:** Omit the `id` field from the JSON payload when creating (not updating) a room.

#### 2.3.8 Double Network Fetch on Status Update

- **File:** `lib/providers/room_provider.dart` (lines 137-159)
- **Description:** After a status update, the provider fetches the room list twice — once explicitly and once via provider invalidation.
- **Fix:** Remove the explicit fetch and rely solely on provider invalidation.

### 2.4 Booking Management

#### 2.4.1 Check-out Date Can Be Set Before Check-in Date

- **File:** `lib/screens/bookings/booking_form_screen.dart` (lines 298-306)
- **Description:** The date picker for check-out does not enforce that it must be after the check-in date. Users can create bookings with inverted date ranges.
- **Fix:** Set the `firstDate` of the check-out picker to the current check-in date + 1 day.

#### 2.4.2 Booking Detail Never Refreshes After Status Changes

- **File:** `lib/screens/bookings/booking_detail_screen.dart`
- **Description:** After changing a booking's status (check-in, check-out, cancel), the detail screen continues showing the old status. The provider is not invalidated.
- **Fix:** Invalidate the booking detail provider after a status change and rebuild the screen.

#### 2.4.3 GuestQuickSearch Dual Controller Conflict

- **File:** `lib/widgets/guests/guest_quick_search.dart` (lines 121-145)
- **Description:** The widget creates its own `TextEditingController` while the parent also passes one in. Both controllers fight for control of the text field, causing unexpected rebuild loops and text flickering.
- **Fix:** Use a single controller — either the parent's or the widget's own, but not both.

#### 2.4.4 "Create New Guest" Button is Non-Functional

- **File:** `lib/widgets/guests/guest_quick_search.dart`
- **Description:** The "Create new guest" option in the search dropdown is a stub that does nothing when tapped.
- **Fix:** Navigate to the guest creation form or show an inline creation dialog.

#### 2.4.5 Room Availability Check Not Implemented

- **File:** `lib/screens/bookings/booking_form_screen.dart`
- **Description:** When creating a booking, there is no check to verify the selected room is available for the chosen dates. Double-bookings are possible.
- **Fix:** Query the API for room availability before allowing submission.

### 2.5 Guest Management

#### 2.5.1 Memory Leak: TextEditingControllers Created in `build()`

- **File:** `lib/screens/guests/guest_form_screen.dart` (line 415)
- **Description:** `TextEditingController` instances are created inside the `build()` method. Each rebuild creates new controllers that are never disposed, causing a memory leak.
- **Fix:** Move controller creation to `initState()` and dispose them in `dispose()`.

#### 2.5.2 AbsorbPointer Blocks Clear Button Taps

- **File:** `lib/screens/guests/guest_form_screen.dart`
- **Description:** Some text fields are wrapped in `AbsorbPointer`, which prevents the clear (X) suffix icon from receiving tap events.
- **Fix:** Remove `AbsorbPointer` or restructure so the clear button is outside the absorbed area.

#### 2.5.3 Date of Birth Shows Wrong Label ("Issue Date")

- **File:** `lib/screens/guests/guest_detail_screen.dart` (lines 326-328)
- **Description:** The date of birth field displays the label "Issue Date" instead of "Date of Birth" due to a wrong localization key.
- **Fix:** Use the correct l10n key for date of birth.

#### 2.5.4 Phone Validation Rejects Valid 11-Digit Numbers

- **File:** `lib/screens/guests/guest_form_screen.dart`
- **Description:** The phone number validation regex only accepts up to 10 digits, rejecting valid 11-digit phone numbers used in some countries (including Vietnam mobile numbers).
- **Fix:** Update the regex to accept 10-11 digit phone numbers.

#### 2.5.5 Infinite Rebuild Loop on Success State

- **File:** `lib/screens/guests/guest_list_screen.dart` (lines 162-168)
- **Description:** When the guest list loads successfully, a listener triggers a state change that causes the provider to reload, which triggers the listener again, creating an infinite loop.
- **Fix:** Add a guard to prevent re-triggering on the same success state.

#### 2.5.6 VIP Toggle Doesn't Update Guest List State

- **File:** `lib/providers/guest_provider.dart` (lines 227-239)
- **Description:** `toggleVipStatus` calls the API but doesn't update the local state or invalidate the guest list provider. The VIP badge doesn't appear/disappear until a manual refresh.
- **Fix:** Update the local guest object in state or invalidate the guest list provider after toggling.

#### 2.5.7 Total Spent Always Shows 0

- **File:** `lib/screens/guests/guest_detail_screen.dart` (lines 199-204)
- **Description:** The "Total Spent" field is hardcoded to display `0` instead of fetching the actual value from the guest's financial records.
- **Fix:** Calculate total spent from the guest's folio/finance data or fetch it from the API.

### 2.6 Finance

#### 2.6.1 Pull-to-Refresh Broken

- **File:** `lib/screens/finance/finance_screen.dart`
- **Description:** Same pattern as the dashboard — `RefreshIndicator` wraps a non-scrollable `Column`.
- **Fix:** Same as dashboard: wrap in `SingleChildScrollView` with `AlwaysScrollableScrollPhysics`.

#### 2.6.2 Notes Double-Concatenated on Every Edit

- **File:** `lib/screens/finance/finance_form_screen.dart` (lines 488-493)
- **Description:** When editing a finance record, the notes field value is concatenated into the description string on every save. Saving the same record multiple times causes the notes to multiply.
- **Fix:** Set the notes value directly instead of concatenating it.

#### 2.6.3 Receipt Download/Share Are Non-Functional Stubs

- **File:** `lib/screens/finance/receipt_preview_screen.dart`
- **Description:** The download and share buttons show SnackBars saying "Coming soon" instead of actual functionality.
- **Fix:** Implement file saving and sharing using `path_provider` and `share_plus`, or remove the buttons.

#### 2.6.4 Direct Repository Instantiation Bypasses DI

- **Files:** `lib/screens/finance/receipt_preview_screen.dart`, `lib/widgets/finance/record_deposit_dialog.dart`
- **Description:** These widgets create `FinanceRepository` instances directly (`FinanceRepository()`) instead of reading them from a Riverpod provider. This breaks dependency injection and makes the code untestable.
- **Fix:** Use `ref.read(financeRepositoryProvider)` instead of direct instantiation.

### 2.7 Housekeeping / Minibar / Folio

#### 2.7.1 Housekeeping Task Form Always Creates (Edit Not Implemented)

- **File:** `lib/screens/housekeeping/task_form_screen.dart`
- **Description:** Even when opened in "edit" mode, the form always creates a new task instead of updating the existing one.
- **Fix:** Check the mode and call the update API when editing.

#### 2.7.2 No Confirmation for Clear Cart

- **File:** `lib/screens/minibar/minibar_pos_screen.dart`
- **Description:** The "Clear Cart" button immediately empties the cart without a confirmation dialog. Accidental taps cause data loss.
- **Fix:** Add a confirmation dialog before clearing.

#### 2.7.3 Listener Accumulation Memory Leak in Minibar Item Form

- **File:** `lib/screens/minibar/minibar_item_form_screen.dart`
- **Description:** The `Autocomplete` widget adds listeners on every rebuild without removing previous ones, causing a memory leak.
- **Fix:** Manage listeners in `initState`/`dispose` or use a `ValueListenableBuilder`.

#### 2.7.4 Folio Void Action Only Discoverable via Long-Press

- **File:** `lib/widgets/folio/folio_item_list_widget.dart`
- **Description:** The only way to void a folio item is via a long-press context menu. There is no visual indicator that this action exists. Users are unlikely to discover it.
- **Fix:** Add a visible action button (e.g., swipe-to-reveal or an icon button).

### 2.8 Settings / Night Audit / Reports

#### 2.8.1 Settings Notification Toggles Don't Visually Toggle

- **File:** `lib/providers/settings_provider.dart`
- **Description:** Tapping notification toggle switches calls the provider but the UI state is not updated. The switches appear to do nothing.
- **Fix:** Ensure the provider notifies listeners after updating the toggle state.

#### 2.8.2 Night Audit Errors Silently Swallowed

- **File:** `lib/screens/night_audit/night_audit_screen.dart`
- **Description:** When the close-day or recalculate operations fail, the error is caught but no feedback is shown to the user. The operation appears to succeed.
- **Fix:** Show an error SnackBar or dialog with the error message.

#### 2.8.3 Currency Parser Misidentifies Small VND Amounts as USD

- **File:** `lib/core/utils/currency_formatter.dart` (lines 79-81)
- **Description:** The parsing heuristic uses the numeric magnitude to guess the currency. Small VND amounts (e.g., 50,000 VND) are misidentified as USD.
- **Fix:** Use explicit currency context instead of guessing from the numeric value.

---

## 3. Medium Severity Issues

### 3.1 Missing `context.mounted` Checks After Async Gaps (~20+ screens)

- **Affected areas:** Login, password change, room status dialog, booking form, guest form, finance form, receipt preview, deposit dialog, night audit, and more.
- **Description:** After `await` calls (API requests, `showDialog`, `showDatePicker`), the code uses `context` without first checking `context.mounted`. If the user navigates away during the async operation, this causes "use of BuildContext across async gaps" errors.
- **Fix:** Add `if (!context.mounted) return;` after every `await` that is followed by a `context` usage.

### 3.2 `void` Async Methods Instead of `Future<void>` (~15+ files)

- **Description:** Many async methods are declared as `void` instead of `Future<void>`. This means exceptions thrown inside them are silently swallowed and callers cannot await their completion.
- **Fix:** Change return type to `Future<void>` and ensure callers properly handle errors.

### 3.3 Hardcoded Colors Breaking Dark Mode (~10+ screens)

- **Affected files:** `dashboard_occupancy_widget.dart`, `booking_detail_screen.dart`, `finance_screen.dart`, `room_detail_screen.dart`, `main.dart`, and others.
- **Description:** Hardcoded `Colors.white`, `Colors.grey[100]`, and other light-theme-specific colors are used directly instead of theme-aware alternatives. These make the UI unreadable in dark mode.
- **Fix:** Replace hardcoded colors with `Theme.of(context).colorScheme` or `Theme.of(context).scaffoldBackgroundColor` equivalents.

### 3.4 Deprecated `withOpacity()` Usage (~30+ instances)

- **Description:** `Color.withOpacity()` is deprecated in favor of `Color.withValues(alpha:)`. Used extensively throughout the codebase.
- **Fix:** Replace all `withOpacity(x)` calls with `withValues(alpha: x)`.

### 3.5 Hardcoded Vietnamese Strings Bypassing l10n System

- **Files:** `lib/providers/auth_provider.dart` (lines 266-276), `lib/models/room.dart`, and various screens.
- **Description:** Error messages and display strings are hardcoded in Vietnamese instead of using the `AppLocalizations` (l10n) system. These cannot be translated if localization is extended.
- **Fix:** Replace all hardcoded strings with l10n keys.

### 3.6 Detail Screens Using Local State Copies Instead of Reactive Providers

- **Affected screens:** Room detail, Booking detail, Guest detail.
- **Description:** These screens copy the data object into a local `State` variable at initialization. After mutations (status change, edit, etc.), the local copy becomes stale because it's not connected to the provider.
- **Fix:** Read data directly from the provider in `build()` or update the local state after mutations.

### 3.7 Provider Invalidation Gaps After Mutations

- **Affected providers:** Room, Guest, Booking, Finance.
- **Description:** After create/update/delete operations, some related providers are not invalidated. For example, updating a room's status doesn't invalidate `roomStatusCountsProvider`, so the dashboard shows stale counts.
- **Fix:** Audit all mutation methods and ensure they invalidate all dependent providers.

### 3.8 Search Bar Clear Buttons Don't Work in Multiple Screens

- **Affected screens:** Room management, Booking calendar, Guest list.
- **Description:** The clear (X) button on search bars either doesn't clear the visible text (no controller) or doesn't reset the filter state (state not updated).
- **Fix:** Link a `TextEditingController` to each search field and clear both the controller and filter state.

### 3.9 Double Network Fetches on Updates

- **Affected:** Room provider, Booking provider.
- **Description:** After a mutation, data is fetched explicitly AND the provider is invalidated (which triggers another fetch). This results in two identical API calls.
- **Fix:** Use only one strategy — either explicit fetch or provider invalidation, not both.

### 3.10 Settings AppBar Button Conflicts with Bottom Navigation

- **File:** `lib/screens/home/home_screen.dart` (lines 44-46)
- **Description:** The Settings icon in the AppBar navigates to the Settings screen, but Settings is also a tab in the bottom navigation. This creates two competing navigation paths that can result in confusing back-stack behavior.
- **Fix:** Remove one of the two navigation paths to Settings.

### 3.11 System Navigation Bar Hardcoded White in Dark Mode

- **File:** `lib/main.dart`
- **Description:** The system navigation bar color is set to white regardless of the theme. In dark mode, this creates a jarring white bar at the bottom of the screen.
- **Fix:** Set the system navigation bar color based on the current theme brightness.

### 3.12 Report Screen State Lost on Navigation

- **File:** `lib/screens/reports/report_screen.dart`
- **Description:** The report providers use `autoDispose`, so navigating away and back clears all report data and selections. The user must re-configure and re-generate the report.
- **Fix:** Remove `autoDispose` from report providers, or preserve user selections in a non-disposed provider.

### 3.13 Settings Flash on Startup

- **File:** `lib/providers/settings_provider.dart`
- **Description:** Settings are loaded asynchronously. On app startup, the default values flash briefly before the actual saved values are loaded, causing a visible theme/locale switch.
- **Fix:** Load settings synchronously from Hive before building the widget tree, or show a loading indicator until settings are ready.

### 3.14 Minibar POS Layout Assumes Wide Screen

- **File:** `lib/screens/minibar/minibar_pos_screen.dart`
- **Description:** The POS layout uses fixed widths and a side-by-side layout that overflows on narrow phone screens (< 360dp width).
- **Fix:** Use a responsive layout that stacks vertically on narrow screens.

### 3.15 Night Audit Date Selector Creates Audit Without Confirmation

- **File:** `lib/screens/night_audit/night_audit_screen.dart`
- **Description:** Selecting a date in the night audit screen immediately creates/loads an audit for that date without asking for confirmation.
- **Fix:** Add a confirmation dialog before creating a new audit.

### 3.16 Booking Source Labels Hardcoded in English

- **File:** `lib/screens/bookings/booking_form_screen.dart`
- **Description:** Booking source options (e.g., "Walk-in", "Phone", "OTA") are hardcoded in English instead of using l10n strings.
- **Fix:** Use l10n keys for all source labels.

### 3.17 Deposit Status Hardcodes VND Currency

- **File:** `lib/widgets/finance/deposit_status.dart`
- **Description:** The deposit status widget always displays "VND" as the currency symbol, regardless of the user's currency setting.
- **Fix:** Read the currency from the settings provider.

### 3.18 Finance Amount Input Cursor Jumps to End

- **File:** `lib/screens/finance/finance_form_screen.dart`
- **Description:** When editing the amount field, the cursor always jumps to the end of the text after each keystroke due to the formatting logic resetting the `TextEditingValue`.
- **Fix:** Preserve the cursor position when formatting the amount.

### 3.19 Finance Category Error Always Visible Before Submission

- **File:** `lib/screens/finance/finance_form_screen.dart`
- **Description:** The category field validation error message is shown immediately when the form loads, before the user has attempted to submit.
- **Fix:** Only show validation errors after the first submission attempt (`autovalidateMode: AutovalidateMode.onUserInteraction`).

### 3.20 Nested Scaffolds

- **Files:** `lib/widgets/main_scaffold.dart`, `lib/screens/home/home_screen.dart`
- **Description:** `MainScaffold` provides a `Scaffold` with bottom navigation, and `HomeScreen` also has its own `Scaffold`. This creates nested scaffolds which can cause unexpected behavior with AppBars, FABs, and SnackBars.
- **Fix:** Remove the inner `Scaffold` from `HomeScreen` and use the outer one from `MainScaffold`.

### 3.21 Deep-Link During Loading State Flashes Login Screen

- **File:** `lib/router/app_router.dart`
- **Description:** When the app is in the loading state (checking auth), deep-link navigation briefly redirects to the login screen before redirecting to the target route once auth is confirmed.
- **Fix:** Show a loading screen instead of the login screen during the auth check.

---

## 4. Low Severity Issues

These are code quality, minor UX, and maintainability issues that don't break functionality but should be addressed over time.

### 4.1 Code Quality

- **Unused parameters:** `todaySummary` in `DashboardRevenueCard` is passed but never used.
- **Unused model properties:** `canMarkAvailable` on Room model is defined but never read.
- **`GlobalKey` singleton coupling** in `app_router.dart` — makes testing difficult.
- **Mixed-language debug strings** — some debug/log messages are in Vietnamese, others in English.
- **Missing `const` constructors** on several stateless widgets.
- **Inconsistent error handling patterns** — some methods use try/catch, others use `.catchError()`, others ignore errors entirely.

### 4.2 Minor UX Issues

- **Revenue card shows zeros silently** — when there's no revenue data, the card shows `0` without indicating whether it's loading, errored, or genuinely zero.
- **"More" tooltip says "Add"** on the guest detail screen's popup menu button (`lib/screens/guests/guest_detail_screen.dart` lines 63-64).
- **Edit/delete buttons always visible on booking detail** regardless of booking status — should be hidden for checked-out or cancelled bookings.
- **Wrong icon on password change screen** — uses `lock_clock` instead of `lock` (`lib/screens/auth/password_change_screen.dart` line 276).
- **Missing semantic labels** on several icon buttons — impacts screen reader accessibility.
- **Delete guest sets state to initial** causing a full-screen flash before the list reloads (`lib/providers/guest_provider.dart`).
- **Email regex too strict** — rejects valid email addresses with newer TLDs (`lib/screens/guests/guest_form_screen.dart`).

### 4.3 Architecture / Maintainability

- **`StatefulWidget` instead of `ConsumerStatefulWidget`** in `receipt_preview_screen.dart` — prevents access to Riverpod `ref`.
- **Refresh uses artificial delay** instead of awaiting data in `finance_screen.dart` (`Future.delayed(300ms)`).
- **Untyped dashboard parameter** in `home_screen.dart` (line 202) — uses `dynamic` instead of proper type.
- **Dual state management** in finance screen — both `FutureProvider` and `StateNotifier` exist but only one is used.

---

## 5. Cross-Cutting Patterns

These patterns appear repeatedly across the codebase and can be addressed systematically:

| Pattern | Occurrences | Recommended Approach |
|---------|-------------|---------------------|
| Missing `context.mounted` checks | ~20+ screens | Create a lint rule or code review checklist item |
| `void` async instead of `Future<void>` | ~15+ files | Bulk-fix with search and replace |
| Hardcoded light-theme colors | ~10+ screens | Replace with `Theme.of(context)` references |
| `withOpacity()` deprecated | ~30+ calls | Bulk-replace with `withValues(alpha:)` |
| Hardcoded Vietnamese strings | ~10+ locations | Extract to l10n ARB files |
| Stale local state copies | ~5 detail screens | Refactor to read directly from providers |
| Missing provider invalidation | ~8 mutation methods | Audit all state mutations |
| Direct repository instantiation | ~3 widgets | Replace with `ref.read(provider)` |
| Search clear button broken | ~3 screens | Add proper `TextEditingController` linkage |
| Double network fetch | ~2 providers | Remove explicit fetch, rely on invalidation |

---

## 6. Recommended Fix Priority

### Phase 1: Critical Issues (7 items)

Fix these first — they represent completely broken core functionality.

1. **Booking calendar `onPageChanged`** — add `setState` call
2. **Booking filter camelCase to snake_case** — use `toApiValue`
3. **Token refresh race condition** — implement mutex/Completer pattern
4. **Report export save to file** — use `path_provider` + `share_plus`
5. **Minibar `processCart` invalidation** — capture `bookingId` before clearing state
6. **Housekeeping mock staff** — fetch real staff from API
7. **Maintenance assignment** — implement or defer from UI

### Phase 2: High Severity (30+ items)

Fix broken interactions users encounter during normal usage:
- Pull-to-refresh on dashboard and finance screens
- All stale detail screens (room, booking, guest)
- Form validation issues (date ranges, phone numbers)
- Memory leaks (controllers in `build()`, listener accumulation)
- Dead buttons (notifications, edit, create guest)
- SnackBar-after-pop crashes

### Phase 3: Medium Severity Cross-Cutting (50+ items)

Address patterns systematically:
- Add `mounted` checks after all async gaps
- Fix all dark mode color issues
- Replace hardcoded strings with l10n keys
- Fix provider invalidation gaps
- Replace `void` async with `Future<void>`
- Fix search clear buttons

### Phase 4: Low Severity (40+ items)

Code quality improvements:
- Remove unused parameters and properties
- Fix minor UX inconsistencies
- Add missing semantic labels
- Clean up architecture issues
