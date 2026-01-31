import 'package:freezed_annotation/freezed_annotation.dart';

part 'declaration.freezed.dart';
part 'declaration.g.dart';

/// Request parameters for declaration export
@freezed
class DeclarationExportRequest with _$DeclarationExportRequest {
  const factory DeclarationExportRequest({
    required DateTime dateFrom,
    required DateTime dateTo,
    @Default(ExportFormat.csv) ExportFormat format,
  }) = _DeclarationExportRequest;

  factory DeclarationExportRequest.fromJson(Map<String, dynamic> json) =>
      _$DeclarationExportRequestFromJson(json);
}

/// Export format enum
enum ExportFormat {
  @JsonValue('csv')
  csv,
  @JsonValue('excel')
  excel,
}

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.excel:
        return 'Excel';
    }
  }

  String get apiValue {
    switch (this) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.excel:
        return 'excel';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.excel:
        return 'xlsx';
    }
  }
}
