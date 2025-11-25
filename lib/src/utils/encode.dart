import '../objects/parse_acl.dart';
import '../objects/parse_file.dart';
import '../objects/parse_geo_point.dart';
import '../objects/parse_object.dart';
import '../objects/parse_relation.dart';
import 'parse_date.dart';

/// Encodes a Dart value to Parse JSON format
dynamic encode(
  dynamic value, {
  bool full = false,
  bool forSaving = false,
  Set<String>? seenObjects,
}) {
  seenObjects ??= {};

  if (value == null) {
    return null;
  }

  // DateTime
  if (value is DateTime) {
    return dateToJson(value);
  }

  // ParseObject
  if (value is ParseObject) {
    // Check for circular references
    final id = value.objectId ?? value.localId;
    if (id != null) {
      if (seenObjects.contains(id)) {
        throw Exception('Circular reference detected');
      }
      seenObjects.add(id);
    }

    if (full) {
      return value.toFullJson();
    }
    return value.toPointer();
  }

  // ParseFile
  if (value is ParseFile) {
    return value.toJson();
  }

  // ParseACL
  if (value is ParseACL) {
    return value.toJson();
  }

  // ParseRelation
  if (value is ParseRelation) {
    return value.toJson();
  }

  // ParseGeoPoint
  if (value is ParseGeoPoint) {
    return value.toJson();
  }

  // List
  if (value is List) {
    return value
        .map(
          (item) => encode(
            item,
            full: full,
            forSaving: forSaving,
            seenObjects: seenObjects,
          ),
        )
        .toList();
  }

  // Map
  if (value is Map) {
    final result = <String, dynamic>{};
    value.forEach((key, val) {
      result[key.toString()] = encode(
        val,
        full: full,
        forSaving: forSaving,
        seenObjects: seenObjects,
      );
    });
    return result;
  }

  // Primitive types (String, num, bool)
  return value;
}

/// Encodes a value specifically for saving operations
Map<String, dynamic> encodeForSaving(dynamic value) {
  if (value == null) {
    return {'__op': 'Delete'};
  }

  final encoded = encode(value, forSaving: true);
  return encoded as Map<String, dynamic>? ?? {'value': encoded};
}
