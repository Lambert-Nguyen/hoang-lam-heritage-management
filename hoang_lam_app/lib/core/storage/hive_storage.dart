import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_constants.dart';

/// Hive local storage manager
class HiveStorage {
  static bool _initialized = false;

  /// Initialize Hive storage
  static Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);
    }

    // Note: Models use Freezed (not Hive codegen), so no TypeAdapters needed.
    // Boxes are opened as dynamic and store JSON maps directly.
    // If offline-first support is added later, generate Hive adapters with
    // @HiveType/@HiveField annotations and register them here.

    _initialized = true;
  }

  /// Open a box (create if not exists)
  static Future<Box<T>> openBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox<T>(name);
    }
    return Hive.box<T>(name);
  }

  /// Get settings box
  static Future<Box<dynamic>> get settingsBox async {
    return await openBox(AppConstants.settingsBox);
  }

  /// Get bookings box
  static Future<Box<dynamic>> get bookingsBox async {
    return await openBox(AppConstants.bookingsBox);
  }

  /// Get rooms box
  static Future<Box<dynamic>> get roomsBox async {
    return await openBox(AppConstants.roomsBox);
  }

  /// Get guests box
  static Future<Box<dynamic>> get guestsBox async {
    return await openBox(AppConstants.guestsBox);
  }

  /// Get finances box
  static Future<Box<dynamic>> get financesBox async {
    return await openBox(AppConstants.financesBox);
  }

  /// Get pending operations box (for offline sync)
  static Future<Box<dynamic>> get pendingOperationsBox async {
    return await openBox(AppConstants.pendingOperationsBox);
  }

  /// Close all boxes
  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }

  /// Clear all data (for logout)
  static Future<void> clearAll() async {
    await Hive.deleteBoxFromDisk(AppConstants.bookingsBox);
    await Hive.deleteBoxFromDisk(AppConstants.roomsBox);
    await Hive.deleteBoxFromDisk(AppConstants.guestsBox);
    await Hive.deleteBoxFromDisk(AppConstants.financesBox);
    await Hive.deleteBoxFromDisk(AppConstants.pendingOperationsBox);
    // Keep settings box
  }

  /// Save a setting
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = await settingsBox;
    await box.put(key, value);
  }

  /// Get a setting
  static Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    final box = await settingsBox;
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Remove a setting
  static Future<void> removeSetting(String key) async {
    final box = await settingsBox;
    await box.delete(key);
  }
}
