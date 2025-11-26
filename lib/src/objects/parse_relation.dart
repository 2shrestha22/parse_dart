import 'parse_object.dart';
import 'parse_query.dart';

/// Represents a relation between Parse objects
///
/// Example:
/// ```dart
/// final relation = object.relation<Comment>('comments');
/// relation.add(comment1);
/// relation.add(comment2);
/// await object.save();
///
/// // Query related objects
/// final query = relation.query();
/// final comments = await query.find();
/// ```
class ParseRelation<T> {
  final Object parent;
  final String key;
  final String? targetClassName;

  final List<Object> _addedObjects = [];
  final List<Object> _removedObjects = [];

  ParseRelation(this.parent, this.key, {this.targetClassName});

  /// Create from JSON
  factory ParseRelation.fromJson(Map<String, dynamic> json) {
    return ParseRelation(
      Object(), // Placeholder parent
      '',
      targetClassName: json['className'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '__type': 'Relation',
      'className': targetClassName,
    };
  }

  /// Add an object to the relation
  void add(Object object) {
    _addedObjects.add(object);
    _removedObjects.remove(object);
  }

  /// Remove an object from the relation
  void remove(Object object) {
    _removedObjects.add(object);
    _addedObjects.remove(object);
  }

  /// Get a query for related objects
  ///
  /// Returns a [ParseQuery] that will find all objects in this relation.
  ///
  /// Example:
  /// ```dart
  /// final relation = post.relation<Comment>('comments');
  /// final query = relation.query();
  /// final comments = await query.find();
  /// ```
  ParseQuery<ParseObject> query() {
    final parentObj = parent as ParseObject?;
    if (parentObj == null) {
      throw StateError(
        'Cannot construct a query for a Relation without a parent',
      );
    }

    final ParseQuery<ParseObject> query;
    if (targetClassName == null) {
      // If targetClassName is not set, query parent's className
      // This matches JS SDK behavior (lines 128-129)
      query = ParseQuery<ParseObject>(parentObj.className);
      // Note: redirectClassNameForKey would be set here in JS SDK
      // but we'll handle this when we need it
    } else {
      query = ParseQuery<ParseObject>(targetClassName!);
    }

    // Set up $relatedTo constraint exactly like JS SDK (lines 133-138)
    query.addCondition('\$relatedTo', 'object', {
      '__type': 'Pointer',
      'className': parentObj.className,
      'objectId': parentObj.objectId,
    });
    query.addCondition('\$relatedTo', 'key', key);

    return query;
  }

  /// Check if there are pending changes
  bool get hasChanges => _addedObjects.isNotEmpty || _removedObjects.isNotEmpty;

  @override
  String toString() =>
      'ParseRelation(key: $key, targetClass: $targetClassName)';
}
