import 'parse_object.dart';

/// Convenience extensions for ParseObject
extension ParseObjectExtensions on ParseObject {
  /// Set multiple fields at once
  ///
  /// This method allows you to set multiple fields in a fluent API style.
  ///
  /// Example:
  /// ```dart
  /// final gameScore = ParseObject('GameScore').setAll({
  ///   'playerName': 'John Doe',
  ///   'score': 1337,
  ///   'cheatMode': false,
  /// });
  ///
  /// // Or with cascade notation:
  /// final post = ParseObject('Post')
  ///   ..setAll({
  ///     'title': 'Hello World',
  ///     'content': 'My first post',
  ///   })
  ///   ..setACL(ParseACL()..setPublicReadAccess(true));
  /// ```
  ParseObject setAll(Map<String, dynamic> data) {
    data.forEach((key, value) => set(key, value));
    return this;
  }
}
