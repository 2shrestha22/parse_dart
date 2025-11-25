/// Abstract storage controller that must be implemented by the application
///
/// The Parse SDK is pure Dart and doesn't include platform-specific storage.
/// Applications must provide their own storage implementation.
///
/// Flutter Example:
/// ```dart
/// import 'package:shared_preferences/shared_preferences.dart';
///
/// class FlutterStorageController implements ParseStorageController {
///   final SharedPreferences _prefs;
///
///   FlutterStorageController(this._prefs);
///
///   @override
///   Future<void> setString(String key, String value) async {
///     await _prefs.setString(key, value);
///   }
///
///   @override
///   Future<String?> getString(String key) async {
///     return _prefs.getString(key);
///   }
///
///   @override
///   Future<void> remove(String key) async {
///     await _prefs.remove(key);
///   }
///
///   @override
///   Future<void> clear() async {
///     await _prefs.clear();
///   }
/// }
///
/// // Initialize Parse with storage
/// final prefs = await SharedPreferences.getInstance();
/// Parse.initialize(
///   applicationId: 'YOUR_APP_ID',
///   serverUrl: 'https://your-server.com/parse',
///   storageController: FlutterStorageController(prefs),
/// );
/// ```
///
/// Dart-only Example (using file system):
/// ```dart
/// import 'dart:io';
/// import 'dart:convert';
///
/// class FileStorageController implements ParseStorageController {
///   final Directory _storageDir;
///
///   FileStorageController(this._storageDir);
///
///   @override
///   Future<void> setString(String key, String value) async {
///     final file = File('${_storageDir.path}/$key');
///     await file.writeAsString(value);
///   }
///
///   @override
///   Future<String?> getString(String key) async {
///     final file = File('${_storageDir.path}/$key');
///     if (await file.exists()) {
///       return await file.readAsString();
///     }
///     return null;
///   }
///
///   @override
///   Future<void> remove(String key) async {
///     final file = File('${_storageDir.path}/$key');
///     if (await file.exists()) {
///       await file.delete();
///     }
///   }
///
///   @override
///   Future<void> clear() async {
///     await for (final entity in _storageDir.list()) {
///       if (entity is File) {
///         await entity.delete();
///       }
///     }
///   }
/// }
/// ```
abstract class ParseStorageController {
  /// Save a string value
  Future<void> setString(String key, String value);

  /// Get a string value
  Future<String?> getString(String key);

  /// Remove a value
  Future<void> remove(String key);

  /// Clear all stored data
  Future<void> clear();
}

/// Internal storage manager used by the SDK
class ParseStorageManager {
  ParseStorageManager._();

  static final ParseStorageManager _instance = ParseStorageManager._();
  static ParseStorageManager get instance => _instance;

  ParseStorageController? _controller;

  /// Set the storage controller (required for persistence)
  void setController(ParseStorageController controller) {
    _controller = controller;
  }

  /// Check if storage is available
  bool get isAvailable => _controller != null;

  /// Save a string value
  Future<void> setString(String key, String value) async {
    if (_controller == null) {
      throw StateError(
        'Storage controller not set. Call Parse.setStorageController() first.',
      );
    }
    await _controller!.setString(key, value);
  }

  /// Get a string value
  Future<String?> getString(String key) async {
    if (_controller == null) return null;
    return await _controller!.getString(key);
  }

  /// Remove a value
  Future<void> remove(String key) async {
    if (_controller == null) return;
    await _controller!.remove(key);
  }

  /// Clear all stored data
  Future<void> clear() async {
    if (_controller == null) return;
    await _controller!.clear();
  }
}
