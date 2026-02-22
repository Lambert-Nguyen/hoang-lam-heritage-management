import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../l10n/app_localizations.dart';

/// iOS-compatible secure storage options
const _iOSOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock,
);

/// Service for handling biometric authentication
class BiometricService {
  static BiometricService? _instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: _iOSOptions,
  );

  // Storage keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserKey = 'biometric_user';

  BiometricService._();

  factory BiometricService() {
    _instance ??= BiometricService._();
    return _instance!;
  }

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometrics are available and enrolled
  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({required String localizedReason}) async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometric login is enabled for the app
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Enable biometric login and store username
  Future<void> enableBiometric(String username) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
    await _secureStorage.write(key: _biometricUserKey, value: username);
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _biometricUserKey);
  }

  /// Get stored username for biometric login
  Future<String?> getBiometricUsername() async {
    return await _secureStorage.read(key: _biometricUserKey);
  }

  /// Get biometric type display name in Vietnamese
  @Deprecated('Use getLocalizedBiometricTypeName instead')
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Vân tay';
    } else if (types.contains(BiometricType.iris)) {
      return 'Quét mống mắt';
    }
    return 'Sinh trắc học';
  }

  /// Get localized biometric type display name
  String getLocalizedBiometricTypeName(
    List<BiometricType> types,
    AppLocalizations l10n,
  ) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID'; // Brand name
    } else if (types.contains(BiometricType.fingerprint)) {
      return l10n.biometricFingerprint;
    } else if (types.contains(BiometricType.iris)) {
      return l10n.biometricIris;
    }
    return l10n.biometricGeneric;
  }
}
