import 'src/core/parse_core_manager.dart';
import 'src/live_query/live_query_client.dart';
import 'src/storage/storage_controller.dart';

export 'src/cloud/parse_cloud.dart';
export 'src/controllers/rest_controller.dart';
export 'src/core/parse_core_manager.dart';
export 'src/core/parse_error.dart';
export 'src/live_query/live_query_client.dart';
export 'src/objects/parse_acl.dart';
export 'src/objects/parse_file.dart';
export 'src/objects/parse_geo_point.dart';
export 'src/objects/parse_object.dart';
export 'src/objects/parse_object_extensions.dart';
export 'src/objects/parse_query.dart';
export 'src/objects/parse_relation.dart';
export 'src/objects/parse_user.dart';
export 'src/operations/parse_operation.dart';
export 'src/storage/storage_controller.dart';

/// Main Parse SDK class
///
/// Entry point for all Parse SDK operations.
///
/// Example:
/// ```dart
/// void main() {
///   Parse.initialize(
///     applicationId: 'YOUR_APP_ID',
///     serverUrl: 'https://your-server.com/parse',
///     clientKey: 'YOUR_CLIENT_KEY',
///   );
///
///   // Now you can use Parse
///   final object = ParseObject('GameScore');
///   object.set('score', 1337);
///   await object.save();
/// }
/// ```
class Parse {
  Parse._();

  /// Initialize the Parse SDK
  ///
  /// This must be called before using any Parse functionality.
  ///
  /// - [applicationId]: Your Parse application ID
  /// - [serverUrl]: URL of your Parse Server
  /// - [clientKey]: Your Parse client key (optional, recommended for security)
  /// - [masterKey]: Your Parse master key (Node.js only, never use in client apps!)
  /// - [liveQueryUrl]: WebSocket URL for LiveQuery (optional, auto-inferred if omitted)
  /// - [storageController]: Storage implementation for persistence (optional but recommended)
  /// - [webSocketFactory]: WebSocket factory for Live Query (optional, required for Live Query)
  ///
  /// Example with storage (Flutter):
  /// ```dart
  /// import 'package:shared_preferences/shared_preferences.dart';
  ///
  /// class MyStorageController implements ParseStorageController {
  ///   final SharedPreferences prefs;
  ///   MyStorageController(this.prefs);
  ///
  ///   @override
  ///   Future<void> setString(String key, String value) async {
  ///     await prefs.setString(key, value);
  ///   }
  ///
  ///   @override
  ///   Future<String?> getString(String key) async {
  ///     return prefs.getString(key);
  ///   }
  ///
  ///   @override
  ///   Future<void> remove(String key) async {
  ///     await prefs.remove(key);
  ///   }
  ///
  ///   @override
  ///   Future<void> clear() async {
  ///     await prefs.clear();
  ///   }
  /// }
  ///
  /// final prefs = await SharedPreferences.getInstance();
  /// Parse.initialize(
  ///   applicationId: 'YOUR_APP_ID',
  ///   serverUrl: 'https://your-server.com/parse',
  ///   clientKey: 'YOUR_CLIENT_KEY',
  ///   storageController: MyStorageController(prefs),
  /// );
  /// ```
  static void initialize({
    required String applicationId,
    required String serverUrl,
    String? clientKey,
    String? masterKey,
    String? liveQueryUrl,
    ParseStorageController? storageController,
    ParseWebSocketClientFactory? webSocketFactory,
  }) {
    ParseCoreManager.instance.initialize(
      applicationId: applicationId,
      serverUrl: serverUrl,
      clientKey: clientKey,
      masterKey: masterKey,
      liveQueryUrl: liveQueryUrl,
      storageController: storageController,
      webSocketFactory: webSocketFactory,
    );
  }

  /// Check if the SDK has been initialized
  static bool get isInitialized => ParseCoreManager.instance.isInitialized;

  /// Get the current application ID
  static String get applicationId => ParseCoreManager.instance.applicationId;

  /// Get the current server URL
  static String get serverUrl => ParseCoreManager.instance.serverUrl;

  /// Get the LiveQuery URL
  static String get liveQueryUrl => ParseCoreManager.instance.liveQueryUrl;

  /// Enable or disable request idempotency
  ///
  /// When enabled, POST and PUT requests will include a unique request ID
  /// to prevent duplicate operations.
  static bool get idempotency => ParseCoreManager.instance.idempotency;
  static set idempotency(bool value) {
    ParseCoreManager.instance.idempotency = value;
  }

  /// Set the number of retry attempts for failed requests
  static int get requestAttemptLimit =>
      ParseCoreManager.instance.requestAttemptLimit;
  static set requestAttemptLimit(int value) {
    ParseCoreManager.instance.requestAttemptLimit = value;
  }

  /// Add a custom header to all Parse requests
  static void setRequestHeader(String key, String value) {
    ParseCoreManager.instance.setRequestHeader(key, value);
  }

  /// Remove a custom header
  static void removeRequestHeader(String key) {
    ParseCoreManager.instance.removeRequestHeader(key);
  }
}
