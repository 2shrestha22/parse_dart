import '../objects/parse_file.dart';
import '../objects/parse_geo_point.dart';
import '../objects/parse_object.dart';
import '../objects/parse_relation.dart';
import 'parse_date.dart';

/// Decodes Parse JSON to Dart objects
dynamic decode(dynamic value) {
  if (value == null) {
    return null;
  }

  // Handle Parse special types
  if (value is Map<String, dynamic>) {
    final type = value['__type'] as String?;

    switch (type) {
      case 'Date':
        return parseDate(value['iso'] as String?);

      case 'Pointer':
        final className = value['className'] as String;
        final objectId = value['objectId'] as String;
        final obj = ParseObject(className);
        obj.objectId = objectId;
        return obj;

      case 'Object':
        final className = value['className'] as String;
        final obj = ParseObject(className);
        if (value.containsKey('objectId')) {
          obj.objectId = value['objectId'] as String;
        }
        // Decode all fields
        value.forEach((key, val) {
          if (key != '__type' && key != 'className') {
            obj.set(key, decode(val));
          }
        });
        return obj;

      case 'File':
        return ParseFile.fromJson(value);

      case 'GeoPoint':
        return ParseGeoPoint.fromJson(value);

      case 'Relation':
        return ParseRelation.fromJson(value);

      default:
        // Regular map - decode recursively
        final result = <String, dynamic>{};
        value.forEach((key, val) {
          result[key] = decode(val);
        });
        return result;
    }
  }

  // List
  if (value is List) {
    return value.map((item) => decode(item)).toList();
  }

  // Primitive types
  return value;
}

/// Decodes a list of Parse objects
List<T> decodeList<T>(List<dynamic>? list) {
  if (list == null) return [];
  return list.map((item) => decode(item) as T).toList();
}
