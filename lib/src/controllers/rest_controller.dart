import 'package:dio/dio.dart';

import '../core/parse_core_manager.dart';
import '../core/parse_error.dart';
import '../utils/uuid.dart';

/// Options for Parse REST requests
class ParseRequestOptions {
  final bool? useMasterKey;
  final String? sessionToken;
  final String? installationId;
  final Map<String, dynamic>? context;
  final bool returnStatus;

  const ParseRequestOptions({
    this.useMasterKey,
    this.sessionToken,
    this.installationId,
    this.context,
    this.returnStatus = false,
  });
}

/// Response from Parse Server
class ParseResponse {
  final Map<String, dynamic> data;
  final int statusCode;
  final Map<String, dynamic> headers;

  const ParseResponse({
    required this.data,
    required this.statusCode,
    this.headers = const {},
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// REST controller for Parse Server communication
class ParseRESTController {
  ParseRESTController._();

  static final ParseRESTController _instance = ParseRESTController._();
  static ParseRESTController get instance => _instance;

  late final Dio _dio;

  /// Initialize the REST controller
  void initialize() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_ParseInterceptor());
  }

  /// Make a request to Parse Server
  Future<ParseResponse> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    ParseRequestOptions options = const ParseRequestOptions(),
  }) async {
    final coreManager = ParseCoreManager.instance;
    coreManager.ensureInitialized();

    final url = '${coreManager.serverUrl}/$path';
    final headers = _buildHeaders(options, method);

    try {
      final response = await _dio.request<Map<String, dynamic>>(
        url,
        data: data,
        options: Options(method: method, headers: headers),
      );

      return ParseResponse(
        data: response.data ?? {},
        statusCode: response.statusCode ?? 0,
        headers: response.headers.map,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Build request headers
  Map<String, String> _buildHeaders(
      ParseRequestOptions options, String method) {
    final coreManager = ParseCoreManager.instance;
    final headers = <String, String>{
      'X-Parse-Application-Id': coreManager.applicationId,
    };

    // Client key
    if (coreManager.clientKey != null) {
      headers['X-Parse-Client-Key'] = coreManager.clientKey!;
    }

    // Master key (use with caution!)
    if (options.useMasterKey == true && coreManager.masterKey != null) {
      headers['X-Parse-Master-Key'] = coreManager.masterKey!;
      headers.remove('X-Parse-Client-Key');
    }

    // Session token
    if (options.sessionToken != null) {
      headers['X-Parse-Session-Token'] = options.sessionToken!;
    }

    // Installation ID
    if (options.installationId != null) {
      headers['X-Parse-Installation-Id'] = options.installationId!;
    }

    // Idempotency
    if (coreManager.idempotency && (method == 'POST' || method == 'PUT')) {
      headers['X-Parse-Request-Id'] = generateUuid();
    }

    // Custom headers
    headers.addAll(coreManager.requestHeaders);

    return headers;
  }

  /// Handle Dio errors
  ParseException _handleError(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return ParseException.fromJson(error.response!.data);
    }

    // Connection errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ParseException(
        code: ParseErrorCode.timeout,
        message: 'Request timed out',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ParseException.connectionFailed();
    }

    // Unknown error
    return ParseException.connectionFailed(error.message);
  }
}

/// Dio interceptor for Parse requests
class _ParseInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Log request (optional)
    // print('Request: ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log response (optional)
    // print('Response: ${response.statusCode}');
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Retry logic
    final coreManager = ParseCoreManager.instance;
    final requestOptions = err.requestOptions;

    // Get current retry count
    final retries = requestOptions.extra['retries'] as int? ?? 0;

    // Check if we should retry
    if (retries < coreManager.requestAttemptLimit - 1 &&
        (err.response?.statusCode == null ||
            err.response!.statusCode! >= 500)) {
      // Exponentially increasing delay
      final delay = Duration(
        milliseconds:
            (125 * (1 << retries) * (0.5 + 0.5 * (retries / 10))).round(),
      );

      await Future.delayed(delay);

      // Create new options with incremented retry count
      final newOptions = requestOptions.copyWith(
        extra: {...requestOptions.extra, 'retries': retries + 1},
      );

      try {
        final response = await Dio().fetch(newOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.reject(e);
      }
    }

    super.onError(err, handler);
  }
}
