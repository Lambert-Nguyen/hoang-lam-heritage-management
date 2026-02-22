import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Mobile/Desktop implementation: saves file to application documents directory.
///
/// Returns the absolute file path.
Future<String> saveFileFromBytes({
  required List<int> bytes,
  required String filename,
  String? mimeType,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$filename';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}

/// Not running on web.
bool get isWebPlatform => false;
