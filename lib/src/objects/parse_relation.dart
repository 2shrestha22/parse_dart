import '../operations/parse_operation.dart';
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
  final ParseObject parent;
  final String key;
  String? targetClassName;

  ParseRelation(this.parent, this.key, {this.targetClassName});

  /// Create from JSON
  factory ParseRelation.fromJson(Map<String, dynamic> json) {
    // Create a placeholder parent for deserialization
    return ParseRelation(
      ParseObject('_Placeholder'),
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

  /// Add an object or array of objects to the relation
  ///
  /// This creates a RelationOperation and applies it to the parent object.
  /// Matches JS SDK behavior (lines 63-79 in ParseRelation.ts)
  void add(dynamic objects) {
    // Convert single object to list
    final List<dynamic> objectList;
    if (objects is List) {
      objectList = objects;
    } else {
      objectList = [objects];
    }

    if (objectList.isEmpty) {
      return;
    }

    // Create the relation operation
    final operation = RelationOperation(
      objectsToAdd: objectList,
      objectsToRemove: const [],
    );

    // Apply to parent (this will merge with existing operations)
    parent.set(key, operation);

    // Extract targetClassName from the operation
    // This matches JS SDK line 77
    if (operation.targetClassName != null) {
      targetClassName = operation.targetClassName;
    }
  }

  /// Remove an object or array of objects from the relation
  ///
  /// This creates a RelationOperation and applies it to the parent object.
  /// Matches JS SDK behavior (lines 86-100 in ParseRelation.ts)
  void remove(dynamic objects) {
    // Convert single object to list
    final List<dynamic> objectList;
    if (objects is List) {
      objectList = objects;
    } else {
      objectList = [objects];
    }

    if (objectList.isEmpty) {
      return;
    }

    // Create the relation operation
    final operation = RelationOperation(
      objectsToAdd: const [],
      objectsToRemove: objectList,
    );

    // Apply to parent (this will merge with existing operations)
    parent.set(key, operation);

    // Extract targetClassName from the operation
    // This matches JS SDK line 99
    if (operation.targetClassName != null) {
      targetClassName = operation.targetClassName;
    }
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
    final ParseQuery<ParseObject> query;
    if (targetClassName == null) {
      // If targetClassName is not set, query parent's className
      // This matches JS SDK behavior (lines 128-129)
      query = ParseQuery<ParseObject>(parent.className);
      // Note: redirectClassNameForKey would be set here in JS SDK
      // but we'll handle this when we need it
    } else {
      query = ParseQuery<ParseObject>(targetClassName!);
    }

    // Set up $relatedTo constraint exactly like JS SDK (lines 133-138)
    query.addCondition('\$relatedTo', 'object', {
      '__type': 'Pointer',
      'className': parent.className,
      'objectId': parent.objectId,
    });
    query.addCondition('\$relatedTo', 'key', key);

    return query;
  }

  @override
  String toString() =>
      'ParseRelation(key: $key, targetClass: $targetClassName)';
}
