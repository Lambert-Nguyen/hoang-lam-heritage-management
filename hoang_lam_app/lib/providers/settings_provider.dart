import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../l10n/app_localizations.dart';

part 'settings_provider.freezed.dart';

/// iOS-compatible secure storage options
const _iOSOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock,
);

/// Keys for secure storage
class SettingsStorageKeys {
  static const String themeMode = 'settings_theme_mode';
  static const String locale = 'settings_locale';
  static const String textScaleFactor = 'settings_text_scale_factor';
  static const String notifyCheckIn = 'settings_notify_check_in';
  static const String notifyCheckOut = 'settings_notify_check_out';
  static const String notifyCleaning = 'settings_notify_cleaning';
}

/// App settings state
@freezed
sealed class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default('vi') String locale,
    @Default(1.0) double textScaleFactor,
    @Default(true) bool notifyCheckIn,
    @Default(true) bool notifyCheckOut,
    @Default(false) bool notifyCleaning,
  }) = _AppSettings;
}

/// Settings notifier for managing app settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  final FlutterSecureStorage _storage;

  SettingsNotifier({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(iOptions: _iOSOptions),
      super(const AppSettings()) {
    _loadSettings();
  }

  /// Load settings from secure storage
  Future<void> _loadSettings() async {
    try {
      // Load theme mode
      final themeModeStr = await _storage.read(
        key: SettingsStorageKeys.themeMode,
      );
      ThemeMode themeMode = ThemeMode.system;
      if (themeModeStr == 'light') {
        themeMode = ThemeMode.light;
      } else if (themeModeStr == 'dark') {
        themeMode = ThemeMode.dark;
      }

      // Load locale
      final locale =
          await _storage.read(key: SettingsStorageKeys.locale) ?? 'vi';

      // Load text scale factor
      final textScaleStr = await _storage.read(
        key: SettingsStorageKeys.textScaleFactor,
      );
      final textScaleFactor = textScaleStr != null
          ? double.tryParse(textScaleStr) ?? 1.0
          : 1.0;

      // Load notification settings
      final notifyCheckInStr = await _storage.read(
        key: SettingsStorageKeys.notifyCheckIn,
      );
      final notifyCheckIn = notifyCheckInStr != 'false';

      final notifyCheckOutStr = await _storage.read(
        key: SettingsStorageKeys.notifyCheckOut,
      );
      final notifyCheckOut = notifyCheckOutStr != 'false';

      final notifyCleaningStr = await _storage.read(
        key: SettingsStorageKeys.notifyCleaning,
      );
      final notifyCleaning = notifyCleaningStr == 'true';

      state = AppSettings(
        themeMode: themeMode,
        locale: locale,
        textScaleFactor: textScaleFactor,
        notifyCheckIn: notifyCheckIn,
        notifyCheckOut: notifyCheckOut,
        notifyCleaning: notifyCleaning,
      );
    } catch (e) {
      // Keep default settings on error
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.write(key: SettingsStorageKeys.themeMode, value: modeStr);
    state = state.copyWith(themeMode: mode);
  }

  /// Set locale
  Future<void> setLocale(String locale) async {
    await _storage.write(key: SettingsStorageKeys.locale, value: locale);
    state = state.copyWith(locale: locale);
  }

  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    await _storage.write(
      key: SettingsStorageKeys.textScaleFactor,
      value: factor.toString(),
    );
    state = state.copyWith(textScaleFactor: factor);
  }

  /// Set notification settings
  Future<void> setNotifyCheckIn(bool value) async {
    await _storage.write(
      key: SettingsStorageKeys.notifyCheckIn,
      value: value.toString(),
    );
    state = state.copyWith(notifyCheckIn: value);
  }

  Future<void> setNotifyCheckOut(bool value) async {
    await _storage.write(
      key: SettingsStorageKeys.notifyCheckOut,
      value: value.toString(),
    );
    state = state.copyWith(notifyCheckOut: value);
  }

  Future<void> setNotifyCleaning(bool value) async {
    await _storage.write(
      key: SettingsStorageKeys.notifyCleaning,
      value: value.toString(),
    );
    state = state.copyWith(notifyCleaning: value);
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _storage.delete(key: SettingsStorageKeys.themeMode);
    await _storage.delete(key: SettingsStorageKeys.locale);
    await _storage.delete(key: SettingsStorageKeys.textScaleFactor);
    await _storage.delete(key: SettingsStorageKeys.notifyCheckIn);
    await _storage.delete(key: SettingsStorageKeys.notifyCheckOut);
    await _storage.delete(key: SettingsStorageKeys.notifyCleaning);
    state = const AppSettings();
  }
}

/// Provider for app settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

/// Provider for theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider.select((s) => s.themeMode));
});

/// Provider for locale
final localeProvider = Provider<Locale>((ref) {
  final localeStr = ref.watch(settingsProvider.select((s) => s.locale));
  return Locale(localeStr);
});

/// Provider for AppLocalizations — use in providers that need localized strings
final l10nProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});

/// Provider for text scale factor
final textScaleFactorProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider.select((s) => s.textScaleFactor));
});
