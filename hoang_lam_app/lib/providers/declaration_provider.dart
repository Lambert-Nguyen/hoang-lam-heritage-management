import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/declaration.dart';
import '../repositories/declaration_repository.dart';

part 'declaration_provider.freezed.dart';

/// Repository provider
final declarationRepositoryProvider = Provider<DeclarationRepository>((ref) {
  return DeclarationRepository();
});

/// State for declaration export
@freezed
class DeclarationExportState with _$DeclarationExportState {
  const factory DeclarationExportState.initial() = DeclarationExportInitial;
  const factory DeclarationExportState.loading() = DeclarationExportLoading;
  const factory DeclarationExportState.success({required String filePath}) =
      DeclarationExportSuccess;
  const factory DeclarationExportState.error({required String message}) =
      DeclarationExportError;
}

/// Notifier for declaration export operations
class DeclarationExportNotifier extends StateNotifier<DeclarationExportState> {
  final DeclarationRepository _repository;

  DeclarationExportNotifier(this._repository)
      : super(const DeclarationExportState.initial());

  /// Export declaration for date range
  Future<void> export({
    required DateTime dateFrom,
    required DateTime dateTo,
    ExportFormat format = ExportFormat.csv,
  }) async {
    state = const DeclarationExportState.loading();

    try {
      final filePath = await _repository.exportDeclaration(
        dateFrom: dateFrom,
        dateTo: dateTo,
        format: format,
      );
      state = DeclarationExportState.success(filePath: filePath);
    } catch (e) {
      state = DeclarationExportState.error(
        message: e.toString(),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const DeclarationExportState.initial();
  }
}

/// Provider for declaration export notifier
final declarationExportProvider =
    StateNotifierProvider<DeclarationExportNotifier, DeclarationExportState>(
        (ref) {
  final repository = ref.watch(declarationRepositoryProvider);
  return DeclarationExportNotifier(repository);
});
