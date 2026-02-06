import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Service to monitor network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  ConnectivityService() {
    _init();
  }

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether device is online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Whether device is offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  void _init() {
    // Get initial status
    _checkConnectivity();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // connectivity_plus returns a list, we take the first result
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _updateStatus([result]);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final newStatus = _mapConnectivityResult(result);
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
    }
  }

  ConnectivityStatus _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return ConnectivityStatus.online;
      case ConnectivityResult.none:
        return ConnectivityStatus.offline;
      default:
        return ConnectivityStatus.unknown;
    }
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}

/// Provider for ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for connectivity status stream
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Provider for current connectivity status
final isOnlineProvider = Provider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnline;
});
