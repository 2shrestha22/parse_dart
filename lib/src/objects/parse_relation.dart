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
  /// This will be properly implemented when ParseQuery is created
  dynamic query() {
    // TODO: Return ParseQuery<T> when implemented
    throw UnimplementedError('ParseQuery not yet implemented');
  }

  /// Check if there are pending changes
  bool get hasChanges => _addedObjects.isNotEmpty || _removedObjects.isNotEmpty;

  @override
  String toString() =>
      'ParseRelation(key: $key, targetClass: $targetClassName)';
}
