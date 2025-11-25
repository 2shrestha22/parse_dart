/// Cloud Code functions
///
/// Call server-side Cloud Code functions.
///
/// Example:
/// ```dart
/// // Define a cloud function on the server
/// Parse.Cloud.define('calculateScore', (request) => {
///   return request.params.level * 100;
/// });
///
/// // Call from client
/// final score = await ParseCloud.run<int>(
///   'calculateScore',
///   parameters: {'level': 5},
/// );
/// print('Score: $score'); // Score: 500
/// ```
library;

import '../controllers/rest_controller.dart';
import '../utils/decode.dart';

class ParseCloud {
  ParseCloud._();

  /// Execute a Cloud Code function
  ///
  /// - [functionName]: Name of the cloud function to call
  /// - [parameters]: Optional parameters to pass to the function
  /// - [options]: Optional request options (session token, etc.)
  ///
  /// Returns the result from the cloud function.
  ///
  /// Example:
  /// ```dart
  /// final result = await ParseCloud.run<Map<String, dynamic>>(
  ///   'getUserStats',
  ///   parameters: {'userId': user.objectId},
  /// );
  /// ```
  static Future<T?> run<T>(
    String functionName, {
    Map<String, dynamic>? parameters,
    ParseRequestOptions? options,
  }) async {
    final restController = ParseRESTController.instance;

    try {
      final response = await restController.request(
        'POST',
        'functions/$functionName',
        data: parameters ?? {},
        options: options ?? const ParseRequestOptions(),
      );

      final result = response.data['result'];
      return decode(result) as T?;
    } catch (e) {
      rethrow;
    }
  }
}
