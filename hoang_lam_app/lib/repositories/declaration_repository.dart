import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/network/api_client.dart';
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
  /// Returns the file path of the downloaded file.
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

    // Get the download directory
    final directory = await getApplicationDocumentsDirectory();
    final formSuffix = formType == DeclarationFormType.all
        ? ''
        : '_${formType.apiValue}';
    final filename =
        'khai_bao_luu_tru${formSuffix}_${dateFromStr}_$dateToStr.${format.fileExtension}';
    final filePath = '${directory.path}/$filename';

    // Download the file
    final response = await _apiClient.dio.get<List<int>>(
      '/guests/declaration-export/',
      queryParameters: queryParams,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': format.mimeType,
        },
      ),
    );

    // Save to file
    final file = File(filePath);
    await file.writeAsBytes(response.data!);

    return filePath;
  }

  /// Format date to YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
