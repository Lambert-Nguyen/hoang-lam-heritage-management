import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth.dart';
import '../models/booking.dart';
import '../models/finance.dart';
import '../models/guest.dart';
import '../models/minibar.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/guest_provider.dart';
import '../providers/housekeeping_provider.dart';
import '../models/room.dart';
import '../models/housekeeping.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/password_change_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/rooms/room_detail_screen.dart';
import '../screens/rooms/room_form_screen.dart';
import '../screens/rooms/room_management_screen.dart';
import '../screens/bookings/bookings_screen.dart';
import '../screens/bookings/booking_form_screen.dart';
import '../screens/bookings/booking_calendar_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/finance/receipt_preview_screen.dart';
import '../screens/minibar/minibar_screens.dart';
import '../screens/guests/guest_detail_screen.dart';
import '../screens/guests/guest_form_screen.dart';
import '../screens/guests/guest_list_screen.dart';
import '../screens/finance/finance_form_screen.dart';
import '../screens/folio/folio_screens.dart';
import '../screens/night_audit/night_audit_screen.dart';
import '../screens/declaration/declaration_export_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/reports/report_screen.dart';
import '../screens/housekeeping/housekeeping_screens.dart';
import '../screens/lost_found/lost_found_list_screen.dart';
import '../screens/lost_found/lost_found_detail_screen.dart';
import '../screens/lost_found/lost_found_form_screen.dart';
import '../screens/group_booking/group_booking_list_screen.dart';
import '../screens/group_booking/group_booking_detail_screen.dart';
import '../screens/group_booking/group_booking_form_screen.dart';
import '../screens/room_inspection/room_inspection_list_screen.dart';
import '../screens/room_inspection/room_inspection_detail_screen.dart';
import '../screens/room_inspection/room_inspection_form_screen.dart';
import '../screens/room_inspection/inspection_template_screen.dart';
import '../screens/pricing/pricing_management_screen.dart';
import '../screens/pricing/rate_plan_form_screen.dart';
import '../screens/pricing/date_rate_override_form_screen.dart';
import '../screens/notifications/notification_list_screen.dart';
import '../screens/messaging/message_template_screen.dart';
import '../screens/messaging/message_history_screen.dart';
import '../screens/finance/financial_category_screen.dart';
import '../screens/settings/staff_management_screen.dart';
import '../l10n/app_localizations.dart';
import '../screens/more/more_menu_screen.dart';
import '../screens/audit_log/audit_log_screen.dart';
import '../widgets/main_scaffold.dart';

/// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String roomDetail = '/room-detail';
  static const String roomManagement = '/room-management';
  static const String roomNew = '/room-management/new';
  static const String roomEdit = '/room-management/edit';
  static const String bookings = '/bookings';
  static const String bookingDetail = '/bookings/:id';
  static const String newBooking = '/bookings/new';
  static const String bookingCalendar = '/booking-calendar';
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
  static const String housekeepingTasks = '/housekeeping';
  static const String housekeepingTaskDetail = '/housekeeping/task';
  static const String housekeepingNewTask = '/housekeeping/new';
  static const String maintenance = '/maintenance';
  static const String maintenanceDetail = '/maintenance/request';
  static const String maintenanceNew = '/maintenance/new';
  // Lost & Found routes
  static const String lostFound = '/lost-found';
  static const String lostFoundNew = '/lost-found/new';
  static const String lostFoundDetail = '/lost-found/:id';
  static const String lostFoundEdit = '/lost-found/:id/edit';
  // Group Booking routes
  static const String groupBookings = '/group-bookings';
  static const String groupBookingNew = '/group-bookings/new';
  static const String groupBookingDetail = '/group-bookings/:id';
  static const String groupBookingEdit = '/group-bookings/:id/edit';
  // Room Inspection routes
  static const String roomInspections = '/room-inspections';
  static const String roomInspectionNew = '/room-inspections/new';
  static const String roomInspectionDetail = '/room-inspections/:id';
  static const String roomInspectionConduct = '/room-inspections/:id/conduct';
  static const String inspectionTemplates = '/inspection-templates';
  // Pricing routes
  static const String pricing = '/pricing';
  static const String ratePlanNew = '/pricing/rate-plans/new';
  static const String ratePlanEdit = '/pricing/rate-plans/:id';
  static const String dateOverrideNew = '/pricing/date-overrides/new';
  static const String dateOverrideEdit = '/pricing/date-overrides/:id';
  // Notification & Messaging routes
  static const String notifications = '/notifications';
  static const String sendMessage = '/send-message';
  static const String messageHistory = '/message-history';
  // Audit log
  static const String auditLog = '/audit-log';
  // More menu
  static const String more = '/more';
  // Settings sub-routes
  static const String financialCategories = '/financial-categories';
  static const String staffManagement = '/staff-management';
  // Guest routes
  static const String guests = '/guests';
  static const String guestDetail = '/guests/detail';
  static const String guestForm = '/guests/form';
  // Finance form route
  static const String financeForm = '/finance/form';
  // Minibar item form route
  static const String minibarItemForm = '/minibar/inventory/form';
}

/// Navigation keys for bottom nav
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// App router configuration
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    // Refresh router when auth state changes (re-evaluates redirects)
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
        path: '${AppRoutes.roomDetail}/:roomId',
        name: 'roomDetail',
        builder: (context, state) {
          // Try extra first (in-app navigation)
          final room = state.extra;
          if (room != null && room is Room) {
            return RoomDetailScreen(room: room);
          }
          // Fall back to fetching by ID (deep link)
          final roomId = int.tryParse(state.pathParameters['roomId'] ?? '');
          if (roomId == null || roomId <= 0) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.l10n.roomInfoNotFound),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: Text(context.l10n.goHome),
                    ),
                  ],
                ),
              ),
            );
          }
          return _RoomDeepLinkScreen(roomId: roomId);
        },
      ),

      // Room Management routes (outside shell for full screen)
      GoRoute(
        path: AppRoutes.roomManagement,
        name: 'roomManagement',
        builder: (context, state) => const RoomManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.roomNew,
        name: 'roomNew',
        builder: (context, state) => const RoomFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.roomEdit,
        name: 'roomEdit',
        builder: (context, state) {
          final room = state.extra as Room?;
          return RoomFormScreen(room: room);
        },
      ),

      // Receipt preview route (outside shell for full screen)
      GoRoute(
        path: '${AppRoutes.receipt}/:bookingId',
        name: 'receipt',
        builder: (context, state) {
          final bookingId = int.tryParse(
            state.pathParameters['bookingId'] ?? '',
          );
          final extra = state.extra as Map<String, dynamic>?;

          if (bookingId == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.bookingInfoNotFound)),
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
          final bookingId = int.tryParse(
            state.pathParameters['bookingId'] ?? '',
          );

          if (bookingId == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.bookingInfoNotFound)),
            );
          }

          return RoomFolioScreen(bookingId: bookingId);
        },
      ),

      // Housekeeping Task Detail (outside shell for full screen)
      GoRoute(
        path: '${AppRoutes.housekeepingTaskDetail}/:taskId',
        name: 'housekeepingTaskDetail',
        builder: (context, state) {
          // Try extra first (in-app navigation)
          final task = state.extra;
          if (task != null && task is HousekeepingTask) {
            return TaskDetailScreen(task: task);
          }
          // Fall back to fetching by ID (deep link)
          final taskId = int.tryParse(state.pathParameters['taskId'] ?? '');
          if (taskId == null || taskId <= 0) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.l10n.taskInfoNotFound),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: Text(context.l10n.goHome),
                    ),
                  ],
                ),
              ),
            );
          }
          return _TaskDeepLinkScreen(taskId: taskId);
        },
      ),

      // New Housekeeping Task (outside shell for full screen)
      GoRoute(
        path: AppRoutes.housekeepingNewTask,
        name: 'housekeepingNewTask',
        builder: (context, state) {
          final task = state.extra as HousekeepingTask?;
          return TaskFormScreen(task: task);
        },
      ),

      // Maintenance Request Detail (outside shell for full screen)
      GoRoute(
        path: '${AppRoutes.maintenanceDetail}/:requestId',
        name: 'maintenanceDetail',
        builder: (context, state) {
          // Try extra first (in-app navigation)
          final request = state.extra;
          if (request != null && request is MaintenanceRequest) {
            return MaintenanceDetailScreen(request: request);
          }
          // Fall back to fetching by ID (deep link)
          final requestId =
              int.tryParse(state.pathParameters['requestId'] ?? '');
          if (requestId == null || requestId <= 0) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.l10n.maintenanceNotFound),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: Text(context.l10n.goHome),
                    ),
                  ],
                ),
              ),
            );
          }
          return _MaintenanceDeepLinkScreen(requestId: requestId);
        },
      ),

      // New Maintenance Request (outside shell for full screen)
      GoRoute(
        path: AppRoutes.maintenanceNew,
        name: 'maintenanceNew',
        builder: (context, state) {
          final request = state.extra as MaintenanceRequest?;
          return MaintenanceFormScreen(request: request);
        },
      ),

      // Lost & Found routes (outside shell for full screen)
      GoRoute(
        path: AppRoutes.lostFoundNew,
        name: 'lostFoundNew',
        builder: (context, state) => const LostFoundFormScreen(),
      ),
      GoRoute(
        path: '/lost-found/:id/edit',
        name: 'lostFoundEdit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.lostItemNotFound)),
            );
          }
          return LostFoundFormScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/lost-found/:id',
        name: 'lostFoundDetail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.lostItemNotFound)),
            );
          }
          return LostFoundDetailScreen(itemId: id);
        },
      ),

      // Group Booking routes (outside shell for full screen)
      GoRoute(
        path: AppRoutes.groupBookingNew,
        name: 'groupBookingNew',
        builder: (context, state) => const GroupBookingFormScreen(),
      ),
      GoRoute(
        path: '/group-bookings/:id/edit',
        name: 'groupBookingEdit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.bookingInfoNotFound)),
            );
          }
          return GroupBookingFormScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/group-bookings/:id',
        name: 'groupBookingDetail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.bookingInfoNotFound)),
            );
          }
          return GroupBookingDetailScreen(bookingId: id);
        },
      ),

      // Room Inspection routes (outside shell for full screen)
      GoRoute(
        path: AppRoutes.roomInspectionNew,
        name: 'roomInspectionNew',
        builder: (context, state) => const RoomInspectionFormScreen(),
      ),
      GoRoute(
        path: '/room-inspections/:id/conduct',
        name: 'roomInspectionConduct',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.roomInfoNotFound)),
            );
          }
          return RoomInspectionFormScreen(
            inspectionId: id,
            isConductMode: true,
          );
        },
      ),
      GoRoute(
        path: '/room-inspections/:id',
        name: 'roomInspectionDetail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.roomInfoNotFound)),
            );
          }
          return RoomInspectionDetailScreen(inspectionId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.inspectionTemplates,
        name: 'inspectionTemplates',
        builder: (context, state) => const InspectionTemplateScreen(),
      ),

      // Notification & Messaging routes (outside shell for full screen)
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: AppRoutes.sendMessage,
        name: 'sendMessage',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final guestId = extra?['guestId'] as int?;
          final guestName = extra?['guestName'] as String?;
          if (extra == null || guestId == null || guestName == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.l10n.guestNotFound),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: Text(context.l10n.goHome),
                    ),
                  ],
                ),
              ),
            );
          }
          return MessageTemplateScreen(
            guestId: guestId,
            guestName: guestName,
            bookingId: extra['bookingId'] as int?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.messageHistory,
        name: 'messageHistory',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MessageHistoryScreen(
            guestId: extra?['guestId'] as int?,
            bookingId: extra?['bookingId'] as int?,
            title: extra?['title'] as String? ?? context.l10n.messageHistory,
          );
        },
      ),

      // Audit log — Manager/Owner only
      GoRoute(
        path: AppRoutes.auditLog,
        name: 'auditLog',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != UserRole.owner && user?.role != UserRole.manager) {
            return AppRoutes.home;
          }
          return null;
        },
        builder: (context, state) => const AuditLogScreen(),
      ),

      // Pricing routes (outside shell for full screen) — Owner only
      GoRoute(
        path: AppRoutes.pricing,
        name: 'pricing',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != UserRole.owner) return AppRoutes.home;
          return null;
        },
        builder: (context, state) => const PricingManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.ratePlanNew,
        name: 'ratePlanNew',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != UserRole.owner) return AppRoutes.home;
          return null;
        },
        builder: (context, state) => const RatePlanFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.ratePlanEdit,
        name: 'ratePlanEdit',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != UserRole.owner) return AppRoutes.home;
          return null;
        },
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.ratePlanNotFound)),
            );
          }
          return RatePlanFormScreen(ratePlanId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.dateOverrideNew,
        name: 'dateOverrideNew',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != UserRole.owner) return AppRoutes.home;
          return null;
        },
        builder: (context, state) => const DateRateOverrideFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.dateOverrideEdit,
        name: 'dateOverrideEdit',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != UserRole.owner) return AppRoutes.home;
          return null;
        },
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(child: Text(context.l10n.dateRateNotFound)),
            );
          }
          return DateRateOverrideFormScreen(overrideId: id);
        },
      ),

      // Financial Categories management — Manager/Owner only
      GoRoute(
        path: AppRoutes.financialCategories,
        name: 'financialCategories',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != UserRole.owner && user?.role != UserRole.manager) {
            return AppRoutes.home;
          }
          return null;
        },
        builder: (context, state) => const FinancialCategoryScreen(),
      ),

      // Guest list route (outside shell for full screen)
      GoRoute(
        path: AppRoutes.guests,
        name: 'guests',
        builder: (context, state) => const GuestListScreen(),
      ),

      // Guest routes (outside shell for full screen)
      GoRoute(
        path: '${AppRoutes.guestDetail}/:guestId',
        name: 'guestDetail',
        builder: (context, state) {
          // Try extra first (in-app navigation)
          final guest = state.extra;
          if (guest != null && guest is Guest) {
            return GuestDetailScreen(guest: guest);
          }
          // Fall back to fetching by ID (deep link)
          final guestId =
              int.tryParse(state.pathParameters['guestId'] ?? '');
          if (guestId == null || guestId <= 0) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.error)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.l10n.guestNotFound),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: Text(context.l10n.goHome),
                    ),
                  ],
                ),
              ),
            );
          }
          return _GuestDeepLinkScreen(guestId: guestId);
        },
      ),
      GoRoute(
        path: AppRoutes.guestForm,
        name: 'guestForm',
        builder: (context, state) {
          final guest = state.extra as Guest?;
          return GuestFormScreen(guest: guest);
        },
      ),

      // Finance Form (outside shell for full screen)
      GoRoute(
        path: AppRoutes.financeForm,
        name: 'financeForm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final entryType =
              extra?['entryType'] as EntryType? ?? EntryType.income;
          final entry = extra?['entry'] as FinancialEntry?;
          return FinanceFormScreen(entryType: entryType, entry: entry);
        },
      ),

      // Minibar Item Form (outside shell for full screen)
      GoRoute(
        path: AppRoutes.minibarItemForm,
        name: 'minibarItemForm',
        builder: (context, state) {
          final item = state.extra as MinibarItem?;
          return MinibarItemFormScreen(item: item);
        },
      ),

      // Staff / Account management
      GoRoute(
        path: AppRoutes.staffManagement,
        name: 'staffManagement',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user?.role != UserRole.owner) return AppRoutes.home;
          return null;
        },
        builder: (context, state) => const StaffManagementScreen(),
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
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),

          // Bookings
          GoRoute(
            path: AppRoutes.bookings,
            name: 'bookings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BookingsScreen()),
            routes: [
              // New Booking (or edit if extra contains a Booking)
              // Also supports Map extras with 'prefilledGuest' for rebook
              GoRoute(
                path: 'new',
                name: 'newBooking',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is Booking) {
                    return BookingFormScreen(booking: extra);
                  }
                  if (extra is Map && extra.containsKey('prefilledGuest')) {
                    final guest = extra['prefilledGuest'] as Guest;
                    return BookingFormScreen(prefilledGuestId: guest.id);
                  }
                  return const BookingFormScreen();
                },
              ),
              // Booking Detail
              GoRoute(
                path: ':id',
                name: 'bookingDetail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return BookingDetailScreen(bookingId: id);
                },
              ),
            ],
          ),

          // Booking Calendar
          GoRoute(
            path: AppRoutes.bookingCalendar,
            name: 'bookingCalendar',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BookingCalendarScreen()),
          ),

          // Finance
          GoRoute(
            path: AppRoutes.finance,
            name: 'finance',
            redirect: (context, state) {
              final user = ref.read(currentUserProvider);
              if (user?.role != UserRole.owner && user?.role != UserRole.manager) {
                return AppRoutes.home;
              }
              return null;
            },
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FinanceScreen()),
          ),

          // Minibar POS
          GoRoute(
            path: AppRoutes.minibarPos,
            name: 'minibarPos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MinibarPosScreen()),
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
            redirect: (context, state) {
              final user = ref.read(currentUserProvider);
              if (user?.role != UserRole.owner && user?.role != UserRole.manager) {
                return AppRoutes.home;
              }
              return null;
            },
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NightAuditScreen()),
          ),

          // Declaration Export — Manager/Owner only
          GoRoute(
            path: AppRoutes.declaration,
            name: 'declaration',
            redirect: (context, state) {
              final user = ref.read(currentUserProvider);
              if (user?.role != UserRole.owner && user?.role != UserRole.manager) {
                return AppRoutes.home;
              }
              return null;
            },
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DeclarationExportScreen()),
          ),

          // Reports & Analytics
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            redirect: (context, state) {
              final user = ref.read(currentUserProvider);
              if (user?.role != UserRole.owner && user?.role != UserRole.manager) {
                return AppRoutes.home;
              }
              return null;
            },
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportScreen()),
          ),

          // Housekeeping Tasks
          GoRoute(
            path: AppRoutes.housekeepingTasks,
            name: 'housekeepingTasks',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TaskListScreen()),
          ),

          // Maintenance Requests
          GoRoute(
            path: AppRoutes.maintenance,
            name: 'maintenance',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MaintenanceListScreen()),
          ),

          // Lost & Found
          GoRoute(
            path: AppRoutes.lostFound,
            name: 'lostFound',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LostFoundListScreen()),
          ),

          // Group Bookings
          GoRoute(
            path: AppRoutes.groupBookings,
            name: 'groupBookings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GroupBookingListScreen()),
          ),

          // Room Inspections
          GoRoute(
            path: AppRoutes.roomInspections,
            name: 'roomInspections',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RoomInspectionListScreen()),
          ),

          // More menu
          GoRoute(
            path: AppRoutes.more,
            name: 'more',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MoreMenuScreen()),
          ),

          // Settings
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.error)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.l10n.pageNotFound,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? context.l10n.errorOccurred),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text(context.l10n.goHome),
            ),
          ],
        ),
      ),
    ),

    // Redirect logic for authentication
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      // Read current auth state (don't watch - refreshListenable handles refresh)
      final authState = ref.read(authStateProvider);
      debugPrint(
        '[Router] redirect called - path: $currentPath, authState: $authState',
      );

      // Check auth state
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );

      final isUnauthenticated = authState.maybeWhen(
        unauthenticated: () => true,
        orElse: () => false,
      );

      final isInitialOrLoading = authState.maybeWhen(
        initial: () => true,
        loading: () => true,
        orElse: () => false,
      );

      // If still checking auth, stay on splash
      if (isInitialOrLoading && currentPath == AppRoutes.splash) {
        debugPrint('[Router] Still loading, staying on splash');
        return null;
      }

      // If unauthenticated and on splash, redirect to login
      if (isUnauthenticated && currentPath == AppRoutes.splash) {
        debugPrint('[Router] Unauthenticated on splash, redirecting to login');
        return AppRoutes.login;
      }

      // Public routes that don't require authentication
      final publicRoutes = [AppRoutes.splash, AppRoutes.login];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isPublicRoute) {
        debugPrint('[Router] Not authenticated, redirecting to login');
        return AppRoutes.login;
      }

      // If authenticated and on login/splash, redirect to home
      if (isAuthenticated &&
          (currentPath == AppRoutes.login || currentPath == AppRoutes.splash)) {
        debugPrint('[Router] Authenticated, redirecting to home');
        return AppRoutes.home;
      }

      debugPrint('[Router] No redirect needed');
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

/// Deep link wrapper: loads Room by ID from API
class _RoomDeepLinkScreen extends ConsumerWidget {
  final int roomId;
  const _RoomDeepLinkScreen({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));
    return roomAsync.when(
      data: (room) => RoomDetailScreen(room: room),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.error)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.roomInfoNotFound),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(context.l10n.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deep link wrapper: loads Guest by ID from API
class _GuestDeepLinkScreen extends ConsumerWidget {
  final int guestId;
  const _GuestDeepLinkScreen({required this.guestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestAsync = ref.watch(guestByIdProvider(guestId));
    return guestAsync.when(
      data: (guest) => GuestDetailScreen(guest: guest),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.error)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.guestNotFound),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(context.l10n.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deep link wrapper: loads HousekeepingTask by ID from API
class _TaskDeepLinkScreen extends ConsumerWidget {
  final int taskId;
  const _TaskDeepLinkScreen({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskByIdProvider(taskId));
    return taskAsync.when(
      data: (task) => TaskDetailScreen(task: task),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.error)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.taskInfoNotFound),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(context.l10n.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deep link wrapper: loads MaintenanceRequest by ID from API
class _MaintenanceDeepLinkScreen extends ConsumerWidget {
  final int requestId;
  const _MaintenanceDeepLinkScreen({required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync =
        ref.watch(maintenanceRequestByIdProvider(requestId));
    return requestAsync.when(
      data: (request) => MaintenanceDetailScreen(request: request),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.error)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.maintenanceNotFound),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(context.l10n.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
