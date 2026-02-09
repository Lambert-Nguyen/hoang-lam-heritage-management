/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Hotel Info
  static const String hotelName = 'Hoàng Lâm Heritage Suites';
  static const String hotelNameEn = 'Hoang Lam Heritage Suites';
  static const int totalRooms = 7;

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String localeKey = 'locale';
  static const String textScaleKey = 'text_scale';
  static const String themeKey = 'theme';
  static const String onboardingCompleteKey = 'onboarding_complete';

  // Hive Box Names
  static const String settingsBox = 'settings';
  static const String bookingsBox = 'bookings';
  static const String roomsBox = 'rooms';
  static const String guestsBox = 'guests';
  static const String financesBox = 'finances';
  static const String pendingOperationsBox = 'pending_operations';

  // API Endpoints
  static const String authLoginEndpoint = '/auth/login/';
  static const String authRefreshEndpoint = '/auth/refresh/';
  static const String authLogoutEndpoint = '/auth/logout/';
  static const String authMeEndpoint = '/auth/me/';
  static const String authPasswordChangeEndpoint = '/auth/password/change/';
  static const String authStaffEndpoint = '/auth/staff/';
  static const String dashboardEndpoint = '/dashboard/';
  static const String roomsEndpoint = '/rooms/';
  static const String roomTypesEndpoint = '/room-types/';
  static const String bookingsEndpoint = '/bookings/';
  static const String guestsEndpoint = '/guests/';
  static const String financesEndpoint = '/finance/entries/';
  static const String categoriesEndpoint = '/finance/categories/';
  static const String reportsEndpoint = '/reports/';
  static const String paymentsEndpoint = '/payments/';
  static const String folioItemsEndpoint = '/folio-items/';
  static const String exchangeRatesEndpoint = '/exchange-rates/';
  static const String receiptsEndpoint = '/receipts/';
  static const String housekeepingTasksEndpoint = '/housekeeping-tasks/';
  static const String maintenanceRequestsEndpoint = '/maintenance-requests/';
  static const String minibarItemsEndpoint = '/minibar-items/';
  static const String minibarSalesEndpoint = '/minibar-sales/';
  static const String lostFoundEndpoint = '/lost-found/';
  static const String groupBookingsEndpoint = '/group-bookings/';
  static const String roomInspectionsEndpoint = '/room-inspections/';
  static const String inspectionTemplatesEndpoint = '/inspection-templates/';
  static const String ratePlansEndpoint = '/rate-plans/';
  static const String dateRateOverridesEndpoint = '/date-rate-overrides/';
  // Phase 5: Notifications & Messaging
  static const String notificationsEndpoint = '/notifications/';
  static const String deviceTokenEndpoint = '/devices/token/';
  static const String notificationPreferencesEndpoint = '/notifications/preferences/';
  static const String messageTemplatesEndpoint = '/message-templates/';
  static const String guestMessagesEndpoint = '/guest-messages/';

  // Date/Time Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateFormatShort = 'dd/MM';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";

  // Currency
  static const String defaultCurrency = 'VND';
  static const String currencySymbol = '₫';
  static const int vndDecimalPlaces = 0;
  static const int usdDecimalPlaces = 2;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Session
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);

  // Check-in/Check-out times
  static const int defaultCheckInHour = 14; // 2 PM
  static const int defaultCheckOutHour = 12; // 12 PM

  // Sync
  static const Duration syncDebounce = Duration(seconds: 2);
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 5);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int phoneNumberLength = 10;
  static const int cccdLength = 12;
  static const int passportMinLength = 6;
  static const int passportMaxLength = 9;

  // UI
  static const double defaultTextScale = 1.0;
  static const double largeTextScale = 1.2;
  static const double extraLargeTextScale = 1.4;
}
