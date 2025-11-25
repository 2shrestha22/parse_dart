/// Parse error codes mapping from Parse Server
class ParseErrorCode {
  // Connection
  static const int connectionFailed = -1;
  static const int timeout = 124;

  // Object errors
  static const int objectNotFound = 101;
  static const int invalidQuery = 102;
  static const int invalidClassName = 103;
  static const int missingObjectId = 104;
  static const int invalidKeyName = 105;
  static const int invalidPointer = 106;
  static const int invalidJSON = 107;
  static const int commandUnavailable = 108;
  static const int notInitialized = 109;
  static const int incorrectType = 111;
  static const int invalidChannelName = 112;
  static const int pushMisconfigured = 115;
  static const int objectTooLarge = 116;
  static const int operationForbidden = 119;
  static const int cacheMiss = 120;
  static const int invalidNestedKey = 121;
  static const int invalidFileName = 122;
  static const int invalidACL = 123;
  static const int invalidEmailAddress = 125;
  static const int duplicateValue = 137;
  static const int invalidRoleName = 139;
  static const int exceededQuota = 140;
  static const int scriptFailed = 141;
  static const int validationError = 142;
  static const int invalidImageData = 150;
  static const int unsavedFileError = 151;
  static const int invalidPushTimeError = 152;
  static const int fileDeleteError = 153;
  static const int requestLimitExceeded = 155;
  static const int invalidEventName = 160;

  // User errors
  static const int usernameMissing = 200;
  static const int passwordMissing = 201;
  static const int usernameTaken = 202;
  static const int emailTaken = 203;
  static const int emailMissing = 204;
  static const int emailNotFound = 205;
  static const int sessionMissing = 206;
  static const int mustCreateUserThroughSignup = 207;
  static const int accountAlreadyLinked = 208;
  static const int invalidSessionToken = 209;
  static const int linkedIdMissing = 250;
  static const int invalidLinkedSession = 251;
  static const int unsupportedService = 252;

  // Other errors
  static const int aggregateError = 600;
  static const int fileReadError = 601;
  static const int xDomainRequest = 602;
}

/// Exception thrown by Parse SDK operations
class ParseException implements Exception {
  /// Error code from Parse Server
  final int code;

  /// Human-readable error message
  final String message;

  /// Additional details about the error (optional)
  final Map<String, dynamic>? details;

  const ParseException({
    required this.code,
    required this.message,
    this.details,
  });

  /// Creates a ParseException from a JSON response
  factory ParseException.fromJson(Map<String, dynamic> json) {
    return ParseException(
      code: json['code'] as int? ?? ParseErrorCode.connectionFailed,
      message: json['error'] as String? ??
          json['message'] as String? ??
          'Unknown error',
      details: json,
    );
  }

  /// Connection failed error
  factory ParseException.connectionFailed([String? message]) {
    return ParseException(
      code: ParseErrorCode.connectionFailed,
      message: message ?? 'Unable to connect to Parse Server',
    );
  }

  /// Invalid session token error
  factory ParseException.invalidSessionToken() {
    return const ParseException(
      code: ParseErrorCode.invalidSessionToken,
      message: 'Invalid session token',
    );
  }

  /// Object not found error
  factory ParseException.objectNotFound(String className, String objectId) {
    return ParseException(
      code: ParseErrorCode.objectNotFound,
      message: 'Object not found: $className:$objectId',
    );
  }

  /// Not initialized error
  factory ParseException.notInitialized() {
    return const ParseException(
      code: ParseErrorCode.notInitialized,
      message: 'Parse SDK not initialized. Call Parse.initialize() first.',
    );
  }

  @override
  String toString() {
    final buffer =
        StringBuffer('ParseException(code: $code, message: $message');
    if (details != null) {
      buffer.write(', details: $details');
    }
    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParseException &&
        other.code == code &&
        other.message == message;
  }

  @override
  int get hashCode => code.hashCode ^ message.hashCode;
}
