import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/services/biometric_service.dart';
import '../l10n/app_localizations.dart';
import 'settings_provider.dart';

/// Provider for BiometricService
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Provider for checking if device supports biometrics
final biometricSupportedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.canCheckBiometrics();
});

/// Provider for available biometric types
final availableBiometricsProvider =
    FutureProvider<List<BiometricType>>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.getAvailableBiometrics();
});

/// Provider for checking if biometric login is enabled
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.isBiometricEnabled();
});

/// Notifier for managing biometric state
class BiometricNotifier extends AsyncNotifier<BiometricState> {
  @override
  Future<BiometricState> build() async {
    final service = ref.watch(biometricServiceProvider);

    final isSupported = await service.canCheckBiometrics();
    final isEnabled = await service.isBiometricEnabled();
    final biometricTypes = await service.getAvailableBiometrics();
    final username = await service.getBiometricUsername();

    return BiometricState(
      isSupported: isSupported,
      isEnabled: isEnabled,
      biometricTypes: biometricTypes,
      storedUsername: username,
    );
  }

  /// Enable biometric login for current user
  Future<void> enableBiometric(String username) async {
    final service = ref.read(biometricServiceProvider);
    await service.enableBiometric(username);
    ref.invalidateSelf();
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    final service = ref.read(biometricServiceProvider);
    await service.disableBiometric();
    ref.invalidateSelf();
  }

  /// Authenticate using biometrics
  Future<bool> authenticate() async {
    final service = ref.read(biometricServiceProvider);
    final l10n = ref.read(l10nProvider);
    return await service.authenticate(
      localizedReason: l10n.biometricAuthenticateLogin,
    );
  }
}

/// Provider for biometric notifier
final biometricNotifierProvider =
    AsyncNotifierProvider<BiometricNotifier, BiometricState>(
  BiometricNotifier.new,
);

/// State class for biometric authentication
class BiometricState {
  final bool isSupported;
  final bool isEnabled;
  final List<BiometricType> biometricTypes;
  final String? storedUsername;

  const BiometricState({
    required this.isSupported,
    required this.isEnabled,
    required this.biometricTypes,
    this.storedUsername,
  });

  /// Get display name for available biometric type
  String get biometricTypeName {
    if (biometricTypes.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometricTypes.contains(BiometricType.fingerprint)) {
      return 'Vân tay';
    } else if (biometricTypes.contains(BiometricType.iris)) {
      return 'Quét mống mắt';
    }
    return 'Sinh trắc học';
  }

  /// Localized biometric type name
  String localizedBiometricTypeName(AppLocalizations l10n) {
    if (biometricTypes.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometricTypes.contains(BiometricType.fingerprint)) {
      return l10n.biometricFingerprint;
    } else if (biometricTypes.contains(BiometricType.iris)) {
      return l10n.biometricIris;
    }
    return l10n.biometricGeneric;
  }

  /// Check if biometric login can be offered
  bool get canUseBiometric => isSupported && isEnabled && storedUsername != null;
}
