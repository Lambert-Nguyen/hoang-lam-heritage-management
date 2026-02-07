# Full i18n Implementation

## Overview

The Hoang Lam Heritage Suites Flutter app now has complete internationalization (i18n) support. All user-facing strings have been extracted to a centralized localization file and can be translated to multiple languages.

## Supported Languages

- **Vietnamese (vi)** - Primary language
- **English (en)** - Secondary language

## Architecture

### Localization File
- Path: `lib/l10n/app_localizations.dart`
- Contains `AppLocalizations` class with 350+ translation keys
- Organized by feature/category for maintainability

### Access Pattern
Use the `context.l10n` extension to access translations:
```dart
import '../../l10n/app_localizations.dart';

// In build method:
Text(context.l10n.login);
Text(context.l10n.bookingDetails);
```

### Categories of Translation Keys

| Category | Description | Example Keys |
|----------|-------------|--------------|
| **Common** | General UI elements | `cancel`, `save`, `confirm`, `delete`, `edit`, `add`, `loading`, `error`, `retry` |
| **Room Status** | Room state labels | `available`, `occupied`, `cleaning`, `maintenance`, `blocked` |
| **Auth** | Login/password screens | `loginSubtitle`, `usernameLabel`, `passwordRequired`, `biometricEnabled` |
| **Dashboard** | Home screen | `roomStatus`, `todayCheckIns`, `todayCheckOuts`, `todayRevenue` |
| **Booking** | Booking management | `bookingList`, `createBooking`, `checkIn`, `checkOut`, `guestInfo`, `payment` |
| **Room** | Room management | `roomManagement`, `addRoom`, `editRoom`, `amenities`, `roomType` |
| **Guest** | Guest management | `guests`, `addGuest`, `fullName`, `phoneNumber`, `nationality`, `gender` |
| **Finance** | Financial entries | `income`, `expense`, `profit`, `totalAmount`, `deposit` |
| **Settings** | App settings | `theme`, `language`, `notifications`, `propertyManagement`, `priceManagement` |
| **Housekeeping** | Task management | `housekeepingTasks`, `pending`, `inProgress`, `completed`, `createNewTask` |
| **Night Audit** | End-of-day checks | `nightAuditTitle`, `performedBy`, `occupancy`, `roomStatistics` |
| **Pricing** | Rate plans | `addRatePlan`, `editRatePlan`, `ratePlanName`, `baseRatePerNight` |
| **Declaration** | Residence reports | `residenceDeclarationTitle`, `exportList`, `exportSuccess` |
| **Minibar** | POS system | `minibarManagement`, `addProduct`, `searchProducts` |
| **Folio** | Room charges | `addCharge`, `cancelCharge`, `chargeCancelledSuccess` |

## Updated Screens

All screens have been updated to use i18n:

### Auth
- `login_screen.dart` - Login form, biometric login, forgot password
- `splash_screen.dart` - App loading screen
- `password_change_screen.dart` - Password change form

### Home
- `home_screen.dart` - Dashboard with room status, check-in/out widgets

### Bookings
- `bookings_screen.dart` - Booking list with filters
- `booking_form_screen.dart` - Create/edit booking
- `booking_detail_screen.dart` - Booking details
- `booking_calendar_screen.dart` - Calendar view

### Rooms
- `room_management_screen.dart` - Room list and management
- `room_form_screen.dart` - Create/edit room
- `room_detail_screen.dart` - Room details

### Guests
- `guest_list_screen.dart` - Guest list with filters
- `guest_form_screen.dart` - Create/edit guest
- `guest_detail_screen.dart` - Guest profile

### Finance
- `finance_screen.dart` - Income/expense list
- `finance_form_screen.dart` - Create/edit entry
- `receipt_preview_screen.dart` - Receipt preview

### Settings
- `settings_screen.dart` - All settings options

### Other Screens
- Housekeeping screens (task list, form, detail, maintenance)
- Night audit screen
- Pricing screens (rate plans, daily rates)
- Declaration export screen
- Minibar screens (inventory, POS, form)
- Room folio screen
- Reports screen
- Lost & found screens
- Room inspection screens
- Group booking screens

## Language Selection

Users can change language in Settings → Language:
1. The setting is persisted in secure storage
2. Language change takes effect immediately
3. The `localeProvider` in `main.dart` drives the app's locale

## Adding New Translations

### 1. Add the key to AppLocalizations class:
```dart
String get newFeature => translate('new_feature');
```

### 2. Add Vietnamese translation:
```dart
const Map<String, String> _viTranslations = {
  // ...
  'new_feature': 'Tính năng mới',
};
```

### 3. Add English translation:
```dart
const Map<String, String> _enTranslations = {
  // ...
  'new_feature': 'New feature',
};
```

### 4. Use in screen:
```dart
Text(context.l10n.newFeature);
```

## Adding New Languages

To add a new language (e.g., Chinese):

1. Add locale to `supportedLocales`:
```dart
static const List<Locale> supportedLocales = [
  Locale('vi'),
  Locale('en'),
  Locale('zh'), // Chinese
];
```

2. Add translation map:
```dart
static final Map<String, Map<String, String>> _translations = {
  'vi': _viTranslations,
  'en': _enTranslations,
  'zh': _zhTranslations,
};
```

3. Create Chinese translations:
```dart
const Map<String, String> _zhTranslations = {
  'app_name': '黄林遗产套房',
  'login': '登录',
  // ... all other keys
};
```

## Testing

The app has been verified:
- ✅ Flutter analyze passes with no errors (only deprecation warnings)
- ✅ Widget tests pass
- ✅ Language switching works in Settings
- ✅ All screens render correctly in both languages

## Best Practices

1. **Always use `context.l10n`** - Never hardcode user-facing strings
2. **Organize keys by feature** - Keep related translations together
3. **Use descriptive key names** - `pleaseEnterUsername` not `msg1`
4. **Include placeholders** - For dynamic content, use string interpolation after translation
5. **Test both languages** - Verify UI layout works for both languages (Vietnamese text is often shorter than English)

---

*Last updated: Phase 1 - Full i18n Implementation*
