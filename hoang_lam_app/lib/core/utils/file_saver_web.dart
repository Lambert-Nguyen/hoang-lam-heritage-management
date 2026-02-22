// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation: triggers a browser download.
///
/// Returns the filename (no real file path on web).
Future<String> saveFileFromBytes({
  required List<int> bytes,
  required String filename,
  String? mimeType,
}) async {
  final blob = html.Blob([
    Uint8List.fromList(bytes),
  ], mimeType ?? 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return filename;
}

/// Running on web.
bool get isWebPlatform => true;
