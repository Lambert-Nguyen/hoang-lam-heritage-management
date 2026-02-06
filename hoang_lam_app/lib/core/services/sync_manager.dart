import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/offline_operation.dart';
import '../storage/hive_storage.dart';
import 'connectivity_service.dart';

/// Sync manager for offline operations
/// 
/// This class handles:
/// - Queueing operations when offline
/// - Syncing operations when online
/// - Retry logic for failed operations
/// - Conflict resolution
class SyncManager {
  final Ref _ref;
  final _uuid = const Uuid();
  
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isSyncing = false;
  
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 30);
  
  SyncManager(this._ref) {
    _init();
  }

  void _init() {
    // Listen to connectivity changes
    final connectivityService = _ref.read(connectivityServiceProvider);
    _connectivitySubscription = connectivityService.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        // Device came online, start syncing
        syncPendingOperations();
      }
    });
  }

  /// Queue an operation for offline sync
  Future<void> queueOperation({
    required EntityType entityType,
    String? entityId,
    required OperationType operationType,
    required Map<String, dynamic> payload,
  }) async {
    final operation = OfflineOperation(
      id: _uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      payload: payload,
      createdAt: DateTime.now(),
    );

    final box = await HiveStorage.pendingOperationsBox;
    await box.put(operation.id, operation.toJson());
  }

  /// Get all pending operations
  Future<List<OfflineOperation>> getPendingOperations() async {
    final box = await HiveStorage.pendingOperationsBox;
    final operations = <OfflineOperation>[];
    
    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null && json is Map) {
        try {
          operations.add(OfflineOperation.fromJson(Map<String, dynamic>.from(json)));
        } catch (e) {
          // Skip invalid operations
        }
      }
    }
    
    // Sort by created_at (oldest first)
    operations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return operations;
  }

  /// Get count of pending operations
  Future<int> getPendingCount() async {
    final box = await HiveStorage.pendingOperationsBox;
    return box.length;
  }

  /// Sync all pending operations
  Future<SyncResult> syncPendingOperations() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }

    final connectivityService = _ref.read(connectivityServiceProvider);
    if (!connectivityService.isOnline) {
      return SyncResult(
        success: false,
        message: 'Device is offline',
      );
    }

    _isSyncing = true;
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      final operations = await getPendingOperations();
      
      for (final operation in operations) {
        try {
          await _executeOperation(operation);
          await _removeOperation(operation.id);
          synced++;
        } catch (e) {
          failed++;
          errors.add('${operation.entityType.name}: $e');
          await _incrementRetryCount(operation, e.toString());
        }
      }

      return SyncResult(
        success: failed == 0,
        synced: synced,
        failed: failed,
        errors: errors,
        message: 'Synced $synced operations, $failed failed',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a single operation
  Future<void> _executeOperation(OfflineOperation operation) async {
    // TODO: Implement actual API calls for each operation type
    // This is a placeholder that should be implemented per entity type
    switch (operation.entityType) {
      case EntityType.booking:
        await _executeBookingOperation(operation);
        break;
      case EntityType.guest:
        await _executeGuestOperation(operation);
        break;
      case EntityType.room:
        await _executeRoomOperation(operation);
        break;
      case EntityType.financialEntry:
        await _executeFinancialEntryOperation(operation);
        break;
      case EntityType.housekeepingTask:
        await _executeHousekeepingOperation(operation);
        break;
      case EntityType.payment:
        await _executePaymentOperation(operation);
        break;
    }
  }

  Future<void> _executeBookingOperation(OfflineOperation operation) async {
    // TODO: Implement booking sync
    // final repository = _ref.read(bookingRepositoryProvider);
    // switch (operation.operationType) {
    //   case OperationType.create:
    //     await repository.create(...);
    //   case OperationType.update:
    //     await repository.update(...);
    //   case OperationType.delete:
    //     await repository.delete(...);
    // }
    throw UnimplementedError('Booking sync not implemented');
  }

  Future<void> _executeGuestOperation(OfflineOperation operation) async {
    // TODO: Implement guest sync
    throw UnimplementedError('Guest sync not implemented');
  }

  Future<void> _executeRoomOperation(OfflineOperation operation) async {
    // TODO: Implement room sync
    throw UnimplementedError('Room sync not implemented');
  }

  Future<void> _executeFinancialEntryOperation(OfflineOperation operation) async {
    // TODO: Implement financial entry sync
    throw UnimplementedError('FinancialEntry sync not implemented');
  }

  Future<void> _executeHousekeepingOperation(OfflineOperation operation) async {
    // TODO: Implement housekeeping sync
    throw UnimplementedError('Housekeeping sync not implemented');
  }

  Future<void> _executePaymentOperation(OfflineOperation operation) async {
    // TODO: Implement payment sync
    throw UnimplementedError('Payment sync not implemented');
  }

  /// Remove an operation from the queue
  Future<void> _removeOperation(String id) async {
    final box = await HiveStorage.pendingOperationsBox;
    await box.delete(id);
  }

  /// Increment retry count for a failed operation
  Future<void> _incrementRetryCount(OfflineOperation operation, String error) async {
    final newRetryCount = operation.retryCount + 1;
    
    if (newRetryCount >= _maxRetries) {
      // Max retries reached, mark as permanently failed
      // TODO: Could move to a "dead letter" box for manual review
      await _removeOperation(operation.id);
      return;
    }

    final updatedOperation = operation.copyWith(
      retryCount: newRetryCount,
      lastError: error,
      isProcessing: false,
    );

    final box = await HiveStorage.pendingOperationsBox;
    await box.put(operation.id, updatedOperation.toJson());
  }

  /// Clear all pending operations (use with caution)
  Future<void> clearAllPending() async {
    final box = await HiveStorage.pendingOperationsBox;
    await box.clear();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
  }
}

/// Result of sync operation
class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final String? message;
  final List<String> errors;

  SyncResult({
    required this.success,
    this.synced = 0,
    this.failed = 0,
    this.message,
    this.errors = const [],
  });
}

/// Provider for SyncManager
final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider for pending operations count
final pendingOperationsCountProvider = FutureProvider<int>((ref) async {
  final manager = ref.watch(syncManagerProvider);
  return manager.getPendingCount();
});
