# Phase 1 Critical Fixes Action Plan

**Date:** January 29, 2026  
**Status:** 🚨 IN PROGRESS  
**Review Source:** Rigorous Phase 1 Frontend Review

---

## Executive Summary

**Test Status:** 171 passed, 20 failed (out of 191 total)

**Issues Identified:**
- 🔴 **18 CRITICAL** - Must fix before MVP (app crashes, security vulnerabilities)
- 🟠 **34 HIGH** - Should fix before MVP (data loss, UX issues)
- 🟡 **51 MEDIUM** - Polish items
- ⚪ **45 LOW** - Minor improvements

---

## 🔴 CRITICAL ISSUES (Priority 1)

### Cross-Cutting Issues (Affects ALL repositories)

#### CC-1: Type Cast Crash ⚠️ APP CRASH
**Impact:** Runtime crash on every non-paginated API response  
**Files:** 
- `room_repository.dart:31,108`
- `guest_repository.dart:46`
- `booking_repository.dart:71`

**Problem:**
```dart
// Current (WRONG)
final rooms = response.data as List<dynamic>; // response.data is Map!
```

**Fix:**
```dart
// Check response structure first
final data = response.data;
if (data is Map<String, dynamic> && data.containsKey('results')) {
  final rooms = (data['results'] as List).map(...);
} else if (data is List) {
  final rooms = (data as List).map(...);
}
```

**Status:** 🔧 FIXING

---

#### CC-2: Force-Unwrap Crash ⚠️ APP CRASH
**Impact:** Crash on 204 No Content or null response body  
**Files:** All repository files

**Problem:**
```dart
response.data!  // Crashes if null
```

**Fix:**
```dart
if (response.data == null) {
  throw AppException('Empty response from server');
}
final data = response.data!;
```

**Status:** 🔧 FIXING

---

#### CC-3: Auth Token Refresh Race Condition ⚠️ AUTH FAILURE
**Impact:** Multiple concurrent 401s cause permanent logout  
**File:** `api_interceptors.dart:32-56`

**Problem:** No request queuing during token refresh

**Fix:** Implement request queue with lock pattern:
```dart
final _refreshLock = Lock();
final _pendingRequests = <RequestOptions>[];

if (_refreshLock.locked) {
  _pendingRequests.add(options);
  await _refreshLock.synchronized(() {});
  // Retry with new token
}
```

**Status:** 🔧 FIXING

---

#### CC-4: Security - Password in toString() 🔐 SECURITY
**Impact:** Passwords/tokens exposed in crash reports and logs  
**Files:** `auth.freezed.dart:235,506,1552`

**Problem:**
```dart
@freezed
class LoginRequest {
  String password;  // Exposed in toString()
}
```

**Fix:**
```dart
@Freezed(toStringOverride: true)
class LoginRequest {
  @JsonKey(includeToJson: true, includeFromJson: true)
  String password;
  
  @override
  String toString() => 'LoginRequest(username: $username)'; // Omit password
}
```

**Status:** 🔧 FIXING

---

#### CC-5: Security - Logging Headers/Body 🔐 SECURITY
**Impact:** Bearer tokens and passwords logged in plaintext  
**File:** `api_interceptors.dart:107-108`

**Problem:**
```dart
print('Headers: ${options.headers}');  // Contains Authorization
print('Body: ${options.data}');        // Contains passwords
```

**Fix:**
```dart
final sanitizedHeaders = Map.from(options.headers)
  ..remove('Authorization');
final sanitizedBody = _sanitizeRequestBody(options.data);
print('Headers: $sanitizedHeaders');
print('Body: $sanitizedBody');
```

**Status:** 🔧 FIXING

---

### Auth-Specific Issues

#### AUTH-1: Error State Race Condition ⚠️ UX BROKEN
**Impact:** Users never see login error messages  
**File:** `auth_provider.dart:124-128`

**Problem:**
```dart
state = AuthState.error(message);
await Future.delayed(Duration(milliseconds: 100));
state = AuthState.unauthenticated(); // Overwrites error!
```

**Fix:**
```dart
state = AuthState.error(message);
// Let UI handle clearing error, don't auto-reset
```

**Status:** 🔧 FIXING

---

### Guest-Specific Issues

#### GUEST-1: Currency Format Compilation Error ⚠️ COMPILE ERROR
**Impact:** App won't compile  
**File:** `guest_history_widget.dart:332`

**Problem:**
```dart
'$formattedđ'  // Parsed as identifier "formattedđ"
```

**Fix:**
```dart
'${formatted}đ'
```

**Status:** 🔧 FIXING

---

#### GUEST-2: Duplicate GuestQuickSearch ⚠️ COMPILE CONFLICT
**Impact:** Compile error if both files imported  
**Files:** 
- `guest_quick_search.dart` (functional)
- `guest_search_bar.dart` (stub)

**Fix:** Remove duplicate from `guest_search_bar.dart`

**Status:** 🔧 FIXING

---

#### GUEST-3: Passport Input Blocks Letters ⚠️ DATA LOSS
**Impact:** Cannot enter passport numbers like "B12345678"  
**File:** `guest_form_screen.dart:243-248`

**Problem:**
```dart
FilteringTextInputFormatter.digitsOnly  // Blocks letters
```

**Fix:**
```dart
// For passport: allow alphanumeric
if (idType == IDType.passport) {
  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]'))
}
```

**Status:** 🔧 FIXING

---

### Booking-Specific Issues

#### BOOK-1: Status Name Snake Case ⚠️ API ERROR
**Impact:** Backend rejects status updates  
**File:** `booking_repository.dart:127`

**Problem:**
```dart
status.name  // Sends "checkedIn"
```

**Fix:**
```dart
@JsonEnum(fieldRename: FieldRename.snake)
enum BookingStatus {
  pending,
  @JsonValue('checked_in')
  checkedIn,
  // ...
}
```

**Status:** 🔧 FIXING

---

#### BOOK-2: Null Fields in PATCH ⚠️ DATA CORRUPTION
**Impact:** PATCH requests may clear data on backend  
**File:** `booking.g.dart:285-303`

**Problem:**
```dart
// Missing includeIfNull: false
{
  "guest_name": null,  // Explicit null sent
  "check_in_date": "2026-01-30"
}
```

**Fix:**
```dart
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class BookingUpdate {
  // ...
}
```

**Status:** 🔧 FIXING

---

### Dashboard-Specific Issues

#### DASH-1: Freezed Version Mismatch ⚠️ COMPILE ERROR
**Impact:** Dashboard tests fail to load  
**File:** `dashboard.dart`

**Problem:** Using `sealed class` but Freezed 2.x installed

**Fix:**
```bash
flutter pub upgrade freezed
dart run build_runner build --delete-conflicting-outputs
```

**Status:** 🔧 FIXING

---

## 🟠 HIGH PRIORITY ISSUES (Priority 2)

### Cross-Cutting
- [ ] Stale local state in detail screens
- [ ] Inconsistent Color API usage (withOpacity vs withValues)
- [ ] TextEditingController memory leaks in build()
- [ ] Incomplete barrel exports

### Auth
- [ ] handleSessionExpired() doesn't await clearAuthData()
- [ ] changePassword() swallows exceptions
- [ ] _isAuthEndpoint() uses String.contains()
- [ ] Biometric login requires valid JWT
- [ ] Splash screen no error handling

### Room
- [ ] Dual color systems inconsistency
- [ ] updateRoomStatus() discards filters
- [ ] SnackBar after Navigator.pop()

### Guest
- [ ] Phone validation 10 vs 10-11 digits
- [ ] GuestQuickSearch controller conflicts
- [ ] totalSpent hardcoded to 0

### Booking
- [ ] Check-in button missing for pending
- [ ] Detail screen doesn't refresh
- [ ] Calendar onPageChanged no setState()
- [ ] No check-out-after-check-in validation

### Dashboard + Infra
- [ ] Untyped dynamic parameters
- [ ] Inconsistent autoDispose
- [ ] Route casting without null check
- [ ] Currency formatter edge cases
- [ ] darkTheme returns lightTheme

---

## 📋 Test Failures (20)

### Booking Card Tests (16 failures)
**File:** `test/widgets/bookings/booking_card_test.dart`  
**Cause:** Widget structure mismatch  
**Status:** 🔧 FIXING

### Dashboard Widget Tests (2 failures)
**File:** `test/widgets/dashboard/*_test.dart`  
**Cause:** Freezed compilation error  
**Status:** 🔧 FIXING (blocked by DASH-1)

### Login Screen Test (1 failure)
**File:** `test/screens/auth/login_screen_test.dart`  
**Cause:** Load error  
**Status:** 🔍 INVESTIGATING

### Card Wrap Test (1 failure)
**File:** `test/widgets/bookings/booking_card_test.dart`  
**Cause:** Widget structure  
**Status:** 🔧 FIXING

---

## 📊 Test Coverage Gaps

### Zero Test Coverage Areas:
- [ ] AuthNotifier (auth_provider.dart) - **Most complex auth logic**
- [ ] API Interceptors - **Token refresh, error mapping**
- [ ] BiometricProvider/Service
- [ ] RoomNotifier (room_provider.dart)
- [ ] RoomStatusDialog, RoomGrid, RoomDetailScreen
- [ ] GuestRepository
- [ ] GuestNotifier (guest_provider.dart)
- [ ] All guest screens
- [ ] All guest widgets
- [ ] BookingNotifier (booking_provider.dart)
- [ ] All booking screens
- [ ] HomeScreen (dashboard)

**Action:** Add comprehensive tests after critical fixes

---

## 🎯 Execution Plan

### Phase 1: Critical Fixes (This Session)
1. ✅ Create this action plan
2. 🔧 Fix CC-1: Type cast crashes
3. 🔧 Fix CC-2: Force-unwrap crashes
4. 🔧 Fix CC-3: Token refresh race
5. 🔧 Fix CC-4 & CC-5: Security issues
6. 🔧 Fix AUTH-1: Error state race
7. 🔧 Fix GUEST-1, GUEST-2, GUEST-3
8. 🔧 Fix BOOK-1, BOOK-2
9. 🔧 Fix DASH-1
10. 🔧 Fix test failures
11. ✅ Re-run all tests
12. ✅ Update TASKS.md
13. ✅ Document all changes

### Phase 2: High Priority (Next Session)
- Fix all HIGH priority issues
- Add missing test coverage

### Phase 3: Medium & Low (Future)
- Address remaining polish items

---

## 📝 Change Log

### 2026-01-29 - Critical Fixes
- [ ] Fixed repository type cast crashes (CC-1)
- [ ] Fixed force-unwrap crashes (CC-2)
- [ ] Fixed auth token refresh race (CC-3)
- [ ] Fixed security issues (CC-4, CC-5)
- [ ] Fixed auth error state (AUTH-1)
- [ ] Fixed guest issues (GUEST-1, GUEST-2, GUEST-3)
- [ ] Fixed booking issues (BOOK-1, BOOK-2)
- [ ] Fixed dashboard Freezed issue (DASH-1)
- [ ] Fixed 20 test failures
- [ ] Re-ran full test suite
- [ ] Updated documentation

---

**Next Steps:** Execute Phase 1 fixes systematically, verify with tests, deploy fixed version.
