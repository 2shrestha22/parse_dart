import '../objects/parse_object.dart';

/// Checks if two objects are deeply equal
bool deepEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;

  // ParseObject equality
  if (a is ParseObject && b is ParseObject) {
    return a.className == b.className && a.objectId == b.objectId;
  }

  // List equality
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  // Map equality
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  // Default equality
  return a == b;
}
