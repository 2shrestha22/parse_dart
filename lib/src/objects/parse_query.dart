import '../controllers/rest_controller.dart';
import '../core/parse_error.dart';
import '../utils/encode.dart';
import 'parse_geo_point.dart';
import 'parse_object.dart';

/// Query builder for Parse objects
///
/// Example:
/// ```dart
/// final query = ParseQuery<GameScore>('GameScore')
///   ..whereEqualTo('playerName', 'Dan')
///   ..whereGreaterThan('score', 1000)
///   ..orderByDescending('score')
///   ..limit(10);
///
/// final results = await query.find();
/// ```
class ParseQuery<T extends ParseObject> {
  final String className;

  final Map<String, dynamic> _where = {};
  final List<String> _include = [];
  final List<String> _select = [];
  final List<String> _order = [];
  int? _limit;
  int? _skip;

  ParseQuery(this.className);

  /// Add a constraint
  void _addCondition(String key, String condition, dynamic value) {
    if (!_where.containsKey(key)) {
      _where[key] = {};
    }

    if (_where[key] is! Map) {
      _where[key] = {};
    }

    (_where[key] as Map<String, dynamic>)[condition] = encode(value);
  }

  /// Equal to
  void whereEqualTo(String key, dynamic value) {
    _where[key] = encode(value);
  }

  /// Not equal to
  void whereNotEqualTo(String key, dynamic value) {
    _addCondition(key, '\$ne', value);
  }

  /// Less than
  void whereLessThan(String key, dynamic value) {
    _addCondition(key, '\$lt', value);
  }

  /// Less than or equal to
  void whereLessThanOrEqualTo(String key, dynamic value) {
    _addCondition(key, '\$lte', value);
  }

  /// Greater than
  void whereGreaterThan(String key, dynamic value) {
    _addCondition(key, '\$gt', value);
  }

  /// Greater than or equal to
  void whereGreaterThanOrEqualTo(String key, dynamic value) {
    _addCondition(key, '\$gte', value);
  }

  /// Contained in list
  void whereContainedIn(String key, List<dynamic> values) {
    _addCondition(key, '\$in', values);
  }

  /// Not contained in list
  void whereNotContainedIn(String key, List<dynamic> values) {
    _addCondition(key, '\$nin', values);
  }

  /// Contains all
  void whereContainsAll(String key, List<dynamic> values) {
    _addCondition(key, '\$all', values);
  }

  /// Exists
  void whereExists(String key) {
    _addCondition(key, '\$exists', true);
  }

  /// Does not exist
  void whereDoesNotExist(String key) {
    _addCondition(key, '\$exists', false);
  }

  /// Matches regex
  void whereMatches(String key, String regex, {String? modifiers}) {
    _addCondition(key, '\$regex', regex);
    if (modifiers != null) {
      _addCondition(key, '\$options', modifiers);
    }
  }

  /// Starts with
  void whereStartsWith(String key, String prefix) {
    whereMatches(key, '^${_regexQuote(prefix)}');
  }

  /// Ends with
  void whereEndsWith(String key, String suffix) {
    whereMatches(key, '${_regexQuote(suffix)}\$');
  }

  /// Contains string
  void whereContains(String key, String substring) {
    whereMatches(key, _regexQuote(substring));
  }

  /// Near geo point
  void whereNear(String key, ParseGeoPoint point) {
    _addCondition(key, '\$nearSphere', point.toJson());
  }

  /// Within distance
  void whereWithinKilometers(
    String key,
    ParseGeoPoint point,
    double maxDistance,
  ) {
    _addCondition(key, '\$nearSphere', point.toJson());
    _addCondition(key, '\$maxDistanceInKilometers', maxDistance);
  }

  /// Within miles
  void whereWithinMiles(
    String key,
    ParseGeoPoint point,
    double maxDistance,
  ) {
    _addCondition(key, '\$nearSphere', point.toJson());
    _addCondition(key, '\$maxDistanceInMiles', maxDistance);
  }

  /// Within geo box
  void whereWithinGeoBox(
    String key,
    ParseGeoPoint southwest,
    ParseGeoPoint northeast,
  ) {
    _addCondition(key, '\$within', {
      '\$box': [southwest.toJson(), northeast.toJson()],
    });
  }

  /// Include related objects
  void include(String key) {
    if (!_include.contains(key)) {
      _include.add(key);
    }
  }

  /// Include multiple keys
  void includeAll(List<String> keys) {
    for (final key in keys) {
      include(key);
    }
  }

  /// Select specific fields
  void select(String key) {
    if (!_select.contains(key)) {
      _select.add(key);
    }
  }

  /// Select multiple fields
  void selectAll(List<String> keys) {
    for (final key in keys) {
      select(key);
    }
  }

  /// Order by ascending
  void orderByAscending(String key) {
    _order.add(key);
  }

  /// Order by descending
  void orderByDescending(String key) {
    _order.add('-$key');
  }

  /// Set limit
  void limit(int value) {
    _limit = value;
  }

  /// Set skip
  void skip(int value) {
    _skip = value;
  }

  /// Build query parameters
  Map<String, dynamic> _buildParameters() {
    final params = <String, dynamic>{};

    if (_where.isNotEmpty) {
      params['where'] = _where;
    }

    if (_include.isNotEmpty) {
      params['include'] = _include.join(',');
    }

    if (_select.isNotEmpty) {
      params['keys'] = _select.join(',');
    }

    if (_order.isNotEmpty) {
      params['order'] = _order.join(',');
    }

    if (_limit != null) {
      params['limit'] = _limit;
    }

    if (_skip != null) {
      params['skip'] = _skip;
    }

    return params;
  }

  /// Find all matching objects
  Future<List<T>> find({ParseRequestOptions? options}) async {
    final restController = ParseRESTController.instance;
    final params = _buildParameters();

    try {
      final response = await restController.request(
        'GET',
        'classes/$className',
        data: params,
        options: options ?? const ParseRequestOptions(),
      );

      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((json) =>
              ParseObject.fromJson(className, json as Map<String, dynamic>)
                  as T)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get first matching object
  Future<T?> first({ParseRequestOptions? options}) async {
    limit(1);
    final results = await find(options: options);
    return results.isEmpty ? null : results.first;
  }

  /// Count matching objects
  Future<int> count({ParseRequestOptions? options}) async {
    final restController = ParseRESTController.instance;
    final params = _buildParameters();
    params['count'] = 1;
    params['limit'] = 0;

    try {
      final response = await restController.request(
        'GET',
        'classes/$className',
        data: params,
        options: options ?? const ParseRequestOptions(),
      );

      return response.data['count'] as int? ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Get object by ID
  Future<T?> get(String objectId, {ParseRequestOptions? options}) async {
    final restController = ParseRESTController.instance;

    try {
      final response = await restController.request(
        'GET',
        'classes/$className/$objectId',
        options: options ?? const ParseRequestOptions(),
      );

      return ParseObject.fromJson(className, response.data) as T;
    } on ParseException catch (e) {
      if (e.code == ParseErrorCode.objectNotFound) {
        return null;
      }
      rethrow;
    }
  }

  String _regexQuote(String s) {
    return s.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (match) => '\\${match.group(0)}',
    );
  }

  @override
  String toString() => 'ParseQuery($className)';
}
