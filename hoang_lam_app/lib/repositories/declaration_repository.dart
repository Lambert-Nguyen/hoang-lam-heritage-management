import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/utils/file_saver.dart' as file_saver;
import '../models/declaration.dart';

/// Repository for handling temporary residence declaration exports.
///
/// Supports two official Vietnamese forms:
/// - ĐD10 (Nghị định 144/2021): Sổ quản lý lưu trú — Vietnamese guests
/// - NA17 (Thông tư 04/2015): Phiếu khai báo tạm trú — Foreign guests
class DeclarationRepository {
  final ApiClient _apiClient;

  DeclarationRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Export declaration data and save to file.
  ///
  /// On mobile/desktop: saves to application documents directory and returns the file path.
  /// On web: triggers a browser download and returns the filename.
  Future<String> exportDeclaration({
    required DateTime dateFrom,
    required DateTime dateTo,
    ExportFormat format = ExportFormat.excel,
    DeclarationFormType formType = DeclarationFormType.all,
  }) async {
    final dateFromStr = _formatDate(dateFrom);
    final dateToStr = _formatDate(dateTo);

    final queryParams = {
      'date_from': dateFromStr,
      'date_to': dateToStr,
      'export_format': format.apiValue,
      'form_type': formType.apiValue,
    };

    final formSuffix =
        formType == DeclarationFormType.all ? '' : '_${formType.apiValue}';
    final filename =
        'khai_bao_luu_tru${formSuffix}_${dateFromStr}_$dateToStr.${format.fileExtension}';

    // Download the file bytes from API
    final response = await _apiClient.dio.get<List<int>>(
      '/guests/declaration-export/',
      queryParameters: queryParams,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': format.mimeType},
      ),
    );

    // Save using platform-aware saver (browser download on web, file on mobile)
    return await file_saver.saveFileFromBytes(
      bytes: response.data!,
      filename: filename,
      mimeType: format.mimeType,
    );
  }

  /// Format date to YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
