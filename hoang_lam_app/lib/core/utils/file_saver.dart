// Platform-aware file saver.
//
// Uses conditional imports to provide the correct implementation:
// - Web: triggers browser download
// - Mobile/Desktop: saves to application documents directory
export 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';
