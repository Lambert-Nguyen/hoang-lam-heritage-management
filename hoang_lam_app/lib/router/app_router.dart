import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth.dart';
import '../providers/auth_provider.dart';
import '../models/room.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/password_change_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/rooms/room_detail_screen.dart';
import '../screens/bookings/bookings_screen.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/finance/receipt_preview_screen.dart';
import '../screens/minibar/minibar_screens.dart';
import '../screens/folio/folio_screens.dart';
import '../screens/night_audit/night_audit_screen.dart';
import '../screens/declaration/declaration_export_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/reports/report_screen.dart';
import '../widgets/main_scaffold.dart';

/// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String roomDetail = '/room-detail';
  static const String bookings = '/bookings';
  static const String bookingDetail = '/bookings/:id';
  static const String newBooking = '/bookings/new';
  static const String finance = '/finance';
  static const String receipt = '/receipt';
  static const String minibarPos = '/minibar';
  static const String minibarInventory = '/minibar/inventory';
  static const String roomFolio = '/folio';
  static const String nightAudit = '/night-audit';
  static const String declaration = '/declaration';
  static const String settings = '/settings';
  static const String passwordChange = '/password-change';
  static const String reports = '/reports';
}

/// Navigation keys for bottom nav
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// App router configuration
final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state for redirect logic
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    // Refresh router when auth state changes
    refreshListenable: _AuthStateRefreshNotifier(ref),

    routes: [
      // Splash screen (initial auth check)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login route (outside shell)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Password change route (outside shell)
      GoRoute(
        path: AppRoutes.passwordChange,
        name: 'passwordChange',
        builder: (context, state) => const PasswordChangeScreen(),
      ),

      // Room detail route (outside shell for full screen)
      GoRoute(
        path: AppRoutes.roomDetail,
        name: 'roomDetail',
        builder: (context, state) {
          final room = state.extra;
          if (room == null || room is! Room) {
            // Handle invalid deep link or missing extra
            return Scaffold(
              appBar: AppBar(title: const Text('Lỗi')),
              body: const Center(
                child: Text('Không tìm thấy thông tin phòng'),
              ),
            );
          }
          return RoomDetailScreen(room: room);
        },
      ),

      // Receipt preview route (outside shell for full screen)
      GoRoute(
        path: '${AppRoutes.receipt}/:bookingId',
        name: 'receipt',
        builder: (context, state) {
          final bookingId = int.tryParse(state.pathParameters['bookingId'] ?? '');
          final extra = state.extra as Map<String, dynamic>?;
          
          if (bookingId == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Lỗi')),
              body: const Center(
                child: Text('Không tìm thấy thông tin đặt phòng'),
              ),
            );
          }
          
          return ReceiptPreviewScreen(
            bookingId: bookingId,
            guestName: extra?['guestName'] as String?,
            roomNumber: extra?['roomNumber'] as String?,
          );
        },
      ),

      // Room Folio route (outside shell for full screen)
      GoRoute(
        path: '${AppRoutes.roomFolio}/:bookingId',
        name: 'roomFolio',
        builder: (context, state) {
          final bookingId = int.tryParse(state.pathParameters['bookingId'] ?? '');
          
          if (bookingId == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Lỗi')),
              body: const Center(
                child: Text('Không tìm thấy thông tin đặt phòng'),
              ),
            );
          }
          
          return RoomFolioScreen(bookingId: bookingId);
        },
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // Home/Dashboard
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),

          // Bookings
          GoRoute(
            path: AppRoutes.bookings,
            name: 'bookings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BookingsScreen(),
            ),
            routes: [
              // New Booking
              GoRoute(
                path: 'new',
                name: 'newBooking',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const Placeholder(
                  child: Center(child: Text('New Booking')),
                ),
              ),
              // Booking Detail
              GoRoute(
                path: ':id',
                name: 'bookingDetail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Placeholder(
                    child: Center(child: Text('Booking $id')),
                  );
                },
              ),
            ],
          ),

          // Finance
          GoRoute(
            path: AppRoutes.finance,
            name: 'finance',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FinanceScreen(),
            ),
          ),

          // Minibar POS
          GoRoute(
            path: AppRoutes.minibarPos,
            name: 'minibarPos',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MinibarPosScreen(),
            ),
            routes: [
              // Minibar Inventory
              GoRoute(
                path: 'inventory',
                name: 'minibarInventory',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const MinibarInventoryScreen(),
              ),
            ],
          ),

          // Night Audit (accessible from settings or home)
          GoRoute(
            path: AppRoutes.nightAudit,
            name: 'nightAudit',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NightAuditScreen(),
            ),
          ),

          // Declaration Export
          GoRoute(
            path: AppRoutes.declaration,
            name: 'declaration',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DeclarationExportScreen(),
            ),
          ),

          // Reports & Analytics
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportScreen(),
            ),
          ),

          // Settings
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Lỗi')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy trang',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Đã xảy ra lỗi'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),

    // Redirect logic for authentication
    redirect: (context, state) {
      final currentPath = state.matchedLocation;

      // Public routes that don't require authentication
      final publicRoutes = [AppRoutes.splash, AppRoutes.login];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // Check auth state
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );

      final isInitialOrLoading = authState.maybeWhen(
        initial: () => true,
        loading: () => true,
        orElse: () => false,
      );

      // If still checking auth, stay on splash
      if (isInitialOrLoading && currentPath == AppRoutes.splash) {
        return null;
      }

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on login/splash, redirect to home
      if (isAuthenticated && (currentPath == AppRoutes.login || currentPath == AppRoutes.splash)) {
        return AppRoutes.home;
      }

      return null;
    },
  );
});

/// Notifier to trigger router refresh when auth state changes
class _AuthStateRefreshNotifier extends ChangeNotifier {
  _AuthStateRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
