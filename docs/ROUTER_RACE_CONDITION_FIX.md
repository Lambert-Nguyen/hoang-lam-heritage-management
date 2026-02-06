# Router Race Condition Fix

## Issue Summary

**Error**: `Multiple widgets used the same GlobalKey`

The app crashed with repeated "GlobalKey" exceptions during authentication flow, causing the splash screen to hang or create duplicate screen instances.

## Symptoms

```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════
The following assertion was thrown while finalizing the widget tree:
Multiple widgets used the same GlobalKey.
The key [GlobalObjectKey int#ca527] was used by multiple widgets.
```

Log showing the race condition:
```
flutter: [SplashScreen] Navigating to home...
flutter: [Router] redirect called - path: /home, authState: AuthState.loading()
flutter: [Router] Not authenticated, redirecting to login
```

The splash screen detected `authenticated` state and navigated to `/home`, but when the router processed that navigation, it still saw `loading()` state and redirected to `/login`. This created multiple screen instances sharing the same GlobalKey.

---

## Root Causes

### 1. Dual Navigation Conflict

**Problem**: Both the splash screen AND the router were trying to handle navigation.

- `SplashScreen` used `ref.listen()` to detect auth changes and called `GoRouter.of(context).go(AppRoutes.home)`
- `GoRouter` also had redirect logic that navigated based on auth state
- This created a race where both tried to navigate simultaneously

**File**: `lib/screens/auth/splash_screen.dart`

```dart
// BEFORE (problematic)
ref.listen<AuthState>(authStateProvider, (previous, next) {
  next.maybeWhen(
    authenticated: (_) {
      _hasNavigated = true;
      GoRouter.of(context).go(AppRoutes.home);  // Manual navigation
    },
    unauthenticated: () {
      _hasNavigated = true;
      GoRouter.of(context).go(AppRoutes.login);  // Manual navigation
    },
    orElse: () {},
  );
});
```

### 2. Router Rebuilding on Auth State Changes

**Problem**: Using `ref.watch()` at the provider level caused the entire `GoRouter` instance to be recreated whenever auth state changed.

**File**: `lib/router/app_router.dart`

```dart
// BEFORE (problematic)
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);  // Rebuilds entire router!
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,  // Same GlobalKey reused
    // ...
  );
});
```

When auth state changed:
1. `ref.watch()` triggered provider rebuild
2. New `GoRouter` instance created with same `_rootNavigatorKey`
3. Old router still had widgets using that key
4. Flutter threw GlobalKey conflict error

---

## Fix Applied

### Fix 1: Remove Manual Navigation from Splash Screen

Let the router handle ALL navigation via its redirect logic. Splash screen now only triggers auth check and displays UI.

**File**: `lib/screens/auth/splash_screen.dart`

```dart
// AFTER (fixed)
@override
Widget build(BuildContext context) {
  // Watch auth state - router will handle redirects automatically
  final authState = ref.watch(authStateProvider);
  debugPrint('[SplashScreen] Current auth state: $authState');
  
  // No manual navigation - router's redirect handles it
  authState.maybeWhen(
    authenticated: (_) {
      debugPrint('[SplashScreen] Authenticated - router will redirect to home');
    },
    unauthenticated: () {
      debugPrint('[SplashScreen] Unauthenticated - router will redirect to login');
    },
    orElse: () {
      debugPrint('[SplashScreen] Still loading: $authState');
    },
  );
  
  return Scaffold(/* ... */);
}
```

### Fix 2: Use `ref.read()` Instead of `ref.watch()` in Router

The router is created once and uses `refreshListenable` to re-evaluate redirects when auth state changes. This prevents router rebuild.

**File**: `lib/router/app_router.dart`

```dart
// AFTER (fixed)
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    
    // This triggers redirect re-evaluation without rebuilding router
    refreshListenable: _AuthStateRefreshNotifier(ref),

    redirect: (context, state) {
      // Read (not watch) current auth state inside redirect
      final authState = ref.read(authStateProvider);
      // ... redirect logic
    },
  );
});
```

---

## How It Works Now

1. **App starts** → Router shows splash screen
2. **Splash screen** → Calls `checkAuthStatus()` which updates auth state
3. **Auth state changes** → `_AuthStateRefreshNotifier` triggers `notifyListeners()`
4. **Router re-evaluates redirects** → `ref.read(authStateProvider)` gets current state
5. **Router navigates** → Single source of truth for navigation

```
┌─────────────────┐
│  SplashScreen   │
│  (UI only)      │
└────────┬────────┘
         │ triggers
         ▼
┌─────────────────┐
│  AuthProvider   │
│  checkAuthStatus│
└────────┬────────┘
         │ updates state
         ▼
┌─────────────────┐
│ RefreshNotifier │
│ notifyListeners │
└────────┬────────┘
         │ triggers
         ▼
┌─────────────────┐
│    GoRouter     │
│   redirect()    │◄── Single navigation source
└─────────────────┘
```

---

## Key Takeaways

1. **Single Source of Truth**: Only ONE component should handle navigation decisions
2. **Never use `ref.watch()` in Provider-level GoRouter**: It rebuilds the entire router
3. **Use `refreshListenable`**: This is the correct way to trigger redirect re-evaluation
4. **Use `ref.read()` inside redirect**: Gets current state without triggering rebuild

---

## Files Modified

- `lib/screens/auth/splash_screen.dart` - Removed manual navigation
- `lib/router/app_router.dart` - Changed `ref.watch()` to `ref.read()` in redirect

## Date Fixed

February 5, 2026
