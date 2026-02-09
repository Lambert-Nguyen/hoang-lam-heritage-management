import 'package:freezed_annotation/freezed_annotation.dart';

part 'declaration.freezed.dart';
part 'declaration.g.dart';

/// Request parameters for declaration export
@freezed
sealed class DeclarationExportRequest with _$DeclarationExportRequest {
  const factory DeclarationExportRequest({
    required DateTime dateFrom,
    required DateTime dateTo,
    @Default(ExportFormat.excel) ExportFormat format,
    @Default(DeclarationFormType.all) DeclarationFormType formType,
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

/// Declaration form type matching Vietnamese official forms
enum DeclarationFormType {
  @JsonValue('dd10')
  dd10, // Mẫu ĐD10 - Vietnamese guests
  @JsonValue('na17')
  na17, // Mẫu NA17 - Foreign guests
  @JsonValue('all')
  all, // Both forms
}

extension DeclarationFormTypeExtension on DeclarationFormType {
  String get displayName {
    switch (this) {
      case DeclarationFormType.dd10:
        return 'ĐD10 - Khách Việt Nam';
      case DeclarationFormType.na17:
        return 'NA17 - Khách nước ngoài';
      case DeclarationFormType.all:
        return 'Tất cả';
    }
  }

  String get description {
    switch (this) {
      case DeclarationFormType.dd10:
        return 'Sổ quản lý lưu trú (Nghị định 144/2021)';
      case DeclarationFormType.na17:
        return 'Phiếu khai báo tạm trú người nước ngoài (Thông tư 04/2015)';
      case DeclarationFormType.all:
        return 'Cả ĐD10 và NA17';
    }
  }

  String get apiValue {
    switch (this) {
      case DeclarationFormType.dd10:
        return 'dd10';
      case DeclarationFormType.na17:
        return 'na17';
      case DeclarationFormType.all:
        return 'all';
    }
  }
}
