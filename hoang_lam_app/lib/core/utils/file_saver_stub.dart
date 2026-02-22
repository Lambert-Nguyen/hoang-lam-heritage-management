// Stub implementation for unsupported platforms.
//
// This should never be used in practice. The conditional imports
// in file_saver.dart will select the correct implementation.

/// Save [bytes] to a file with the given [filename] and [mimeType].
/// Returns the file path (or filename on web).
Future<String> saveFileFromBytes({
  required List<int> bytes,
  required String filename,
  String? mimeType,
}) async {
  throw UnsupportedError('File saving is not supported on this platform');
}

/// Whether the current platform is web (browser download).
bool get isWebPlatform => false;
