import 'package:freezed_annotation/freezed_annotation.dart';

part 'offline_operation.freezed.dart';
part 'offline_operation.g.dart';

/// Operation type for offline queue
enum OperationType {
  @JsonValue('create')
  create,
  @JsonValue('update')
  update,
  @JsonValue('delete')
  delete,
}

/// Entity type for offline operations
enum EntityType {
  @JsonValue('booking')
  booking,
  @JsonValue('guest')
  guest,
  @JsonValue('room')
  room,
  @JsonValue('financial_entry')
  financialEntry,
  @JsonValue('housekeeping_task')
  housekeepingTask,
  @JsonValue('payment')
  payment,
}

/// Offline operation model for pending sync
@freezed
sealed class OfflineOperation with _$OfflineOperation {
  const factory OfflineOperation({
    required String id,
    @JsonKey(name: 'entity_type') required EntityType entityType,
    @JsonKey(name: 'entity_id') String? entityId,
    @JsonKey(name: 'operation_type') required OperationType operationType,
    required Map<String, dynamic> payload,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'retry_count') @Default(0) int retryCount,
    @JsonKey(name: 'last_error') String? lastError,
    @JsonKey(name: 'is_processing') @Default(false) bool isProcessing,
  }) = _OfflineOperation;

  factory OfflineOperation.fromJson(Map<String, dynamic> json) =>
      _$OfflineOperationFromJson(json);
}
