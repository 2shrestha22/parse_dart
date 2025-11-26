import '../controllers/rest_controller.dart';
import '../live_query/live_query_client.dart';
import '../storage/storage_controller.dart';
import 'parse_error.dart';

/// Core manager for Parse SDK configuration
///
/// This class manages all SDK configuration and provides access to
/// controllers throughout the application.
class ParseCoreManager {
  ParseCoreManager._();

  static final ParseCoreManager _instance = ParseCoreManager._();
  static ParseCoreManager get instance => _instance;

  // Configuration
  String? _applicationId;
  String? _clientKey;
  String? _masterKey;
  String? _serverUrl;
  String? _liveQueryUrl;

  // Settings
  bool idempotency = false;
  int requestAttemptLimit = 3;
  final Map<String, String> _requestHeaders = {};

  /// Initialize the Parse SDK
  ///
  /// Must be called before any Parse operations.
  ///
  /// ```dart
  /// ParseCoreManager.instance.initialize(
  ///   applicationId: 'YOUR_APP_ID',
  ///   serverUrl: 'https://your-server.com/parse',
  ///   clientKey: 'YOUR_CLIENT_KEY',
  /// );
  /// ```
  void initialize({
    required String applicationId,
    required String serverUrl,
    String? clientKey,
    String? masterKey,
    String? liveQueryUrl,
    ParseStorageController? storageController,
    ParseWebSocketClientFactory? webSocketFactory,
  }) {
    _applicationId = applicationId;
    _serverUrl = _normalizeUrl(serverUrl);
    _clientKey = clientKey;
    _masterKey = masterKey;
    _liveQueryUrl = liveQueryUrl ?? _inferLiveQueryUrl(serverUrl);

    // Set storage controller if provided
    if (storageController != null) {
      ParseStorageManager.instance.setController(storageController);
    }

    // Set WebSocket factory if provided
    if (webSocketFactory != null) {
      ParseLiveQueryClient.instance.setWebSocketFactory(webSocketFactory);
    }

    // Initialize REST controller
    ParseRESTController.instance.initialize();
  }

  /// Normalize server URL
  String _normalizeUrl(String url) {
    if (!url.endsWith('/')) {
      return url;
    }
    return url.substring(0, url.length - 1);
  }

  /// Infer LiveQuery URL from server URL
  String _inferLiveQueryUrl(String serverUrl) {
    return serverUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
  }

  /// Check if SDK is initialized
  bool get isInitialized => _applicationId != null && _serverUrl != null;

  /// Ensure SDK is initialized
  void ensureInitialized() {
    if (!isInitialized) {
      throw ParseException.notInitialized();
    }
  }

  // Getters
  String get applicationId {
    ensureInitialized();
    return _applicationId!;
  }

  String get serverUrl {
    ensureInitialized();
    return _serverUrl!;
  }

  String? get clientKey => _clientKey;
  String? get masterKey => _masterKey;

  String get liveQueryUrl {
    ensureInitialized();
    return _liveQueryUrl!;
  }

  Map<String, String> get requestHeaders => Map.unmodifiable(_requestHeaders);

  void setRequestHeader(String key, String value) {
    _requestHeaders[key] = value;
  }

  void removeRequestHeader(String key) {
    _requestHeaders.remove(key);
  }

  void clearRequestHeaders() {
    _requestHeaders.clear();
  }
}
