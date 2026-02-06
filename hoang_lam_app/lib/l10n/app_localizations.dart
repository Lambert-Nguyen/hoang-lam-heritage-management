import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// App localization support
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('vi'), // Vietnamese (primary)
    Locale('en'), // English
  ];

  // Check if current locale is Vietnamese
  bool get isVietnamese => locale.languageCode == 'vi';

  // Translations map
  static final Map<String, Map<String, String>> _translations = {
    'vi': _viTranslations,
    'en': _enTranslations,
  };

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['vi']?[key] ??
        key;
  }

  // Common translations
  String get appName => translate('app_name');
  String get home => translate('home');
  String get bookings => translate('bookings');
  String get finance => translate('finance');
  String get settings => translate('settings');
  String get login => translate('login');
  String get logout => translate('logout');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get confirm => translate('confirm');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get search => translate('search');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get retry => translate('retry');
  String get noData => translate('no_data');
  String get offline => translate('offline');

  // Room status
  String get available => translate('available');
  String get occupied => translate('occupied');
  String get cleaning => translate('cleaning');
  String get maintenance => translate('maintenance');

  // Booking
  String get checkIn => translate('check_in');
  String get checkOut => translate('check_out');
  String get guestName => translate('guest_name');
  String get guestPhone => translate('guest_phone');
  String get roomNumber => translate('room_number');
  String get nights => translate('nights');
  String get totalAmount => translate('total_amount');
  String get deposit => translate('deposit');
  String get balance => translate('balance');

  // Finance
  String get income => translate('income');
  String get expense => translate('expense');
  String get profit => translate('profit');
  String get today => translate('today');
  String get thisMonth => translate('this_month');

  // Dashboard
  String get roomsAvailable => translate('rooms_available');
  String get todayCheckIns => translate('today_check_ins');
  String get todayCheckOuts => translate('today_check_outs');
  String get todayRevenue => translate('today_revenue');
}

// Vietnamese translations
const Map<String, String> _viTranslations = {
  'app_name': 'Hoàng Lâm Heritage Suites',
  'home': 'Trang chủ',
  'bookings': 'Đặt phòng',
  'finance': 'Tài chính',
  'settings': 'Cài đặt',
  'login': 'Đăng nhập',
  'logout': 'Đăng xuất',
  'cancel': 'Hủy',
  'save': 'Lưu',
  'confirm': 'Xác nhận',
  'delete': 'Xóa',
  'edit': 'Sửa',
  'add': 'Thêm',
  'search': 'Tìm kiếm',
  'loading': 'Đang tải...',
  'error': 'Lỗi',
  'success': 'Thành công',
  'retry': 'Thử lại',
  'no_data': 'Không có dữ liệu',
  'offline': 'Đang offline',

  // Room status
  'available': 'Trống',
  'occupied': 'Có khách',
  'cleaning': 'Đang dọn',
  'maintenance': 'Bảo trì',

  // Booking
  'check_in': 'Nhận phòng',
  'check_out': 'Trả phòng',
  'guest_name': 'Tên khách',
  'guest_phone': 'Số điện thoại',
  'room_number': 'Số phòng',
  'nights': 'đêm',
  'total_amount': 'Tổng tiền',
  'deposit': 'Đặt cọc',
  'balance': 'Còn lại',

  // Finance
  'income': 'Thu nhập',
  'expense': 'Chi phí',
  'profit': 'Lợi nhuận',
  'today': 'Hôm nay',
  'this_month': 'Tháng này',

  // Dashboard
  'rooms_available': 'Phòng trống',
  'today_check_ins': 'Check-in hôm nay',
  'today_check_outs': 'Check-out hôm nay',
  'today_revenue': 'Thu nhập hôm nay',
};

// English translations
const Map<String, String> _enTranslations = {
  'app_name': 'Hoang Lam Heritage',
  'home': 'Home',
  'bookings': 'Bookings',
  'finance': 'Finance',
  'settings': 'Settings',
  'login': 'Login',
  'logout': 'Logout',
  'cancel': 'Cancel',
  'save': 'Save',
  'confirm': 'Confirm',
  'delete': 'Delete',
  'edit': 'Edit',
  'add': 'Add',
  'search': 'Search',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'retry': 'Retry',
  'no_data': 'No data',
  'offline': 'Offline',

  // Room status
  'available': 'Available',
  'occupied': 'Occupied',
  'cleaning': 'Cleaning',
  'maintenance': 'Maintenance',

  // Booking
  'check_in': 'Check-in',
  'check_out': 'Check-out',
  'guest_name': 'Guest name',
  'guest_phone': 'Phone number',
  'room_number': 'Room number',
  'nights': 'nights',
  'total_amount': 'Total amount',
  'deposit': 'Deposit',
  'balance': 'Balance',

  // Finance
  'income': 'Income',
  'expense': 'Expense',
  'profit': 'Profit',
  'today': 'Today',
  'this_month': 'This month',

  // Dashboard
  'rooms_available': 'Rooms available',
  'today_check_ins': 'Today\'s check-ins',
  'today_check_outs': 'Today\'s check-outs',
  'today_revenue': 'Today\'s revenue',
};

// Delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extension for easy access
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
