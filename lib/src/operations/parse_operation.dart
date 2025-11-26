import '../utils/encode.dart';

/// Base class for all Parse operations
///
/// Operations represent changes to fields in a ParseObject.
/// They are used to track modifications and send efficient updates
/// to the server.
abstract class ParseOperation {
  /// Apply this operation to a value
  dynamic apply(dynamic oldValue);

  /// Convert this operation to JSON for the REST API
  Map<String, dynamic> toJson();

  /// Merge this operation with another operation for the same field
  ParseOperation? merge(ParseOperation? previous) => this;
}

/// Set operation - sets a field to a specific value
class SetOperation extends ParseOperation {
  final dynamic value;

  SetOperation(this.value);

  @override
  dynamic apply(dynamic oldValue) => value;

  @override
  Map<String, dynamic> toJson() => encode(value) as Map<String, dynamic>;

  @override
  ParseOperation merge(ParseOperation? previous) => this;
}

/// Unset operation - removes a field
class UnsetOperation extends ParseOperation {
  UnsetOperation();

  @override
  dynamic apply(dynamic oldValue) => null;

  @override
  Map<String, dynamic> toJson() => {'__op': 'Delete'};

  @override
  ParseOperation merge(ParseOperation? previous) => this;
}

/// Increment operation - increments a numeric field
class IncrementOperation extends ParseOperation {
  final num amount;

  IncrementOperation(this.amount);

  @override
  dynamic apply(dynamic oldValue) {
    if (oldValue == null) return amount;
    if (oldValue is num) return oldValue + amount;
    throw ArgumentError('Cannot increment non-numeric value');
  }

  @override
  Map<String, dynamic> toJson() => {
        '__op': 'Increment',
        'amount': amount,
      };

  @override
  ParseOperation merge(ParseOperation? previous) {
    if (previous == null) return this;
    if (previous is IncrementOperation) {
      return IncrementOperation(amount + previous.amount);
    }
    if (previous is SetOperation) {
      final oldValue = previous.value;
      if (oldValue is num) {
        return SetOperation(oldValue + amount);
      }
    }
    return this;
  }
}

/// Add operation - adds items to an array
class AddOperation extends ParseOperation {
  final List<dynamic> objects;

  AddOperation(this.objects);

  @override
  dynamic apply(dynamic oldValue) {
    if (oldValue == null) return [...objects];
    if (oldValue is List) return [...oldValue, ...objects];
    throw ArgumentError('Cannot add to non-array value');
  }

  @override
  Map<String, dynamic> toJson() => {
        '__op': 'Add',
        'objects': objects.map((o) => encode(o)).toList(),
      };

  @override
  ParseOperation merge(ParseOperation? previous) {
    if (previous == null) return this;
    if (previous is AddOperation) {
      return AddOperation([...previous.objects, ...objects]);
    }
    if (previous is SetOperation && previous.value is List) {
      return SetOperation([...previous.value as List, ...objects]);
    }
    return this;
  }
}

/// AddUnique operation - adds items to an array only if they don't exist
class AddUniqueOperation extends ParseOperation {
  final List<dynamic> objects;

  AddUniqueOperation(this.objects);

  @override
  dynamic apply(dynamic oldValue) {
    if (oldValue == null) return [...objects];
    if (oldValue is! List) {
      throw ArgumentError('Cannot add to non-array value');
    }

    final result = [...oldValue];
    for (final obj in objects) {
      if (!result.contains(obj)) {
        result.add(obj);
      }
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson() => {
        '__op': 'AddUnique',
        'objects': objects.map((o) => encode(o)).toList(),
      };

  @override
  ParseOperation merge(ParseOperation? previous) {
    if (previous == null) return this;
    if (previous is AddUniqueOperation) {
      // Merge unique objects
      final merged = <dynamic>{...previous.objects, ...objects}.toList();
      return AddUniqueOperation(merged);
    }
    if (previous is SetOperation && previous.value is List) {
      final result = [...previous.value as List];
      for (final obj in objects) {
        if (!result.contains(obj)) result.add(obj);
      }
      return SetOperation(result);
    }
    return this;
  }
}

/// Remove operation - removes items from an array
class RemoveOperation extends ParseOperation {
  final List<dynamic> objects;

  RemoveOperation(this.objects);

  @override
  dynamic apply(dynamic oldValue) {
    if (oldValue == null) return [];
    if (oldValue is! List) {
      throw ArgumentError('Cannot remove from non-array value');
    }

    final result = [...oldValue];
    for (final obj in objects) {
      result.remove(obj);
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson() => {
        '__op': 'Remove',
        'objects': objects.map((o) => encode(o)).toList(),
      };

  @override
  ParseOperation merge(ParseOperation? previous) {
    if (previous == null) return this;
    if (previous is RemoveOperation) {
      return RemoveOperation([...previous.objects, ...objects]);
    }
    if (previous is SetOperation && previous.value is List) {
      final result = [...previous.value as List];
      for (final obj in objects) {
        result.remove(obj);
      }
      return SetOperation(result);
    }
    return this;
  }
}

/// Relation operation - modifies a relation
class RelationOperation extends ParseOperation {
  final List<dynamic> objectsToAdd;
  final List<dynamic> objectsToRemove;

  RelationOperation({
    this.objectsToAdd = const [],
    this.objectsToRemove = const [],
  });

  @override
  dynamic apply(dynamic oldValue) {
    // Relations are handled server-side
    return oldValue;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (objectsToAdd.isNotEmpty) {
      json['__op'] = 'AddRelation';
      json['objects'] = objectsToAdd.map((o) => encode(o)).toList();
    } else if (objectsToRemove.isNotEmpty) {
      json['__op'] = 'RemoveRelation';
      json['objects'] = objectsToRemove.map((o) => encode(o)).toList();
    }

    return json;
  }

  @override
  ParseOperation merge(ParseOperation? previous) {
    if (previous == null) return this;
    if (previous is RelationOperation) {
      return RelationOperation(
        objectsToAdd: [...previous.objectsToAdd, ...objectsToAdd],
        objectsToRemove: [...previous.objectsToRemove, ...objectsToRemove],
      );
    }
    return this;
  }
}
