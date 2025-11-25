import 'package:meta/meta.dart';

import '../controllers/rest_controller.dart';
import '../core/parse_error.dart';
import '../utils/decode.dart';
import '../utils/encode.dart';
import '../utils/parse_date.dart';
import '../utils/uuid.dart';
import 'parse_acl.dart';
import 'parse_relation.dart';

/// Base class for all Parse objects
///
/// Represents an object stored in Parse Server.
///
/// Example:
/// ```dart
/// // Define a custom class
/// class GameScore extends ParseObject {
///   GameScore() : super('GameScore');
///
///   int? get score => get<int>('score');
///   set score(int? value) => set('score', value);
/// }
///
/// // Use it
/// final gameScore = GameScore()
///   ..score = 1337;
/// await gameScore.save();
/// ```
class ParseObject {
  /// The class name for this object
  final String className;

  /// Server-assigned unique ID
  String? objectId;

  /// Local ID for unsaved objects
  String? localId;

  /// Server data (after fetch/save)
  @protected
  final Map<String, dynamic> serverData = {};

  /// Local changes not yet saved
  @protected
  final Map<String, dynamic> localData = {};

  /// Dirty keys tracking
  final Set<String> _dirtyKeys = {};

  /// Creation timestamp
  DateTime? _createdAt;

  /// Last update timestamp
  DateTime? _updatedAt;

  /// Access Control List
  ParseACL? _acl;

  /// Protected setter for createdAt (for subclasses)
  @protected
  set createdAt(DateTime? value) => _createdAt = value;

  /// Protected setter for updatedAt (for subclasses)
  @protected
  set updatedAt(DateTime? value) => _updatedAt = value;

  /// Protected setter for ACL (for subclasses)
  @protected
  set aclValue(ParseACL? value) => _acl = value;

  ParseObject(this.className);

  /// Create from JSON
  factory ParseObject.fromJson(String className, Map<String, dynamic> json) {
    final object = ParseObject(className);

    if (json.containsKey('objectId')) {
      object.objectId = json['objectId'] as String;
    }

    if (json.containsKey('createdAt')) {
      object._createdAt = parseDate(json['createdAt'] as String);
    }

    if (json.containsKey('updatedAt')) {
      object._updatedAt = parseDate(json['updatedAt'] as String);
    }

    if (json.containsKey('ACL')) {
      object._acl = ParseACL.fromJson(json['ACL'] as Map<String, dynamic>);
    }

    // Decode all other fields
    json.forEach((key, value) {
      if (!['objectId', 'createdAt', 'updatedAt', 'ACL', '__type', 'className']
          .contains(key)) {
        object.serverData[key] = decode(value);
      }
    });

    return object;
  }

  /// Get the creation timestamp
  DateTime? get createdAt => _createdAt;

  /// Get the last update timestamp
  DateTime? get updatedAt => _updatedAt;

  /// Get the ACL
  ParseACL? get acl => _acl;

  /// Set the ACL
  void setACL(ParseACL acl) {
    _acl = acl;
    _dirtyKeys.add('ACL');
  }

  /// Get a value by key
  T? get<T>(String key) {
    // Check local data first (unsaved changes)
    if (localData.containsKey(key)) {
      return localData[key] as T?;
    }
    // Fall back to server data
    return serverData[key] as T?;
  }

  /// Set a value by key
  void set<T>(String key, T? value) {
    if (key == 'objectId' ||
        key == 'createdAt' ||
        key == 'updatedAt' ||
        key == 'ACL') {
      throw ParseException(
        code: ParseErrorCode.invalidKeyName,
        message: 'Cannot set reserved key: $key',
      );
    }

    if (value == null) {
      localData[key] = null;
    } else {
      localData[key] = value;
    }
    _dirtyKeys.add(key);
  }

  /// Unset a value (remove it)
  void unset(String key) {
    localData.remove(key);
    serverData.remove(key);
    _dirtyKeys.add(key);
  }

  /// Increment a numeric value
  void increment(String key, [num amount = 1]) {
    final currentValue = get<num>(key) ?? 0;
    set(key, currentValue + amount);
  }

  /// Get a relation
  ParseRelation<T> relation<T>(String key) {
    return ParseRelation<T>(this, key);
  }

  /// Check if this object has been saved
  bool get isSaved => objectId != null;

  /// Check if this object has unsaved changes
  bool get isDirty => _dirtyKeys.isNotEmpty;

  /// Get list of dirty keys
  List<String> get dirtyKeys => _dirtyKeys.toList();

  /// Check if a specific key is dirty
  bool isKeyDirty(String key) => _dirtyKeys.contains(key);

  /// Save the object to Parse Server
  Future<void> save({ParseRequestOptions? options}) async {
    final restController = ParseRESTController.instance;

    // Build the save data
    final data = <String, dynamic>{};

    // Add ACL if present and dirty
    if (_acl != null && _dirtyKeys.contains('ACL')) {
      data['ACL'] = _acl!.toJson();
    }

    // Add dirty fields
    for (final key in _dirtyKeys) {
      if (key != 'ACL') {
        final value = localData[key];
        data[key] = encode(value);
      }
    }

    // Determine method and path
    final bool isNew = objectId == null;
    final method = isNew ? 'POST' : 'PUT';
    final path = isNew ? 'classes/$className' : 'classes/$className/$objectId';

    try {
      final response = await restController.request(
        method,
        path,
        data: data,
        options: options ?? const ParseRequestOptions(),
      );

      // Update from response
      handleSaveResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch the latest data from Parse Server
  Future<void> fetch({ParseRequestOptions? options}) async {
    if (objectId == null) {
      throw const ParseException(
        code: ParseErrorCode.missingObjectId,
        message: 'Cannot fetch object without objectId',
      );
    }

    final restController = ParseRESTController.instance;

    try {
      final response = await restController.request(
        'GET',
        'classes/$className/$objectId',
        options: options ?? const ParseRequestOptions(),
      );

      _handleFetchResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete the object from Parse Server
  Future<void> delete({ParseRequestOptions? options}) async {
    if (objectId == null) {
      throw const ParseException(
        code: ParseErrorCode.missingObjectId,
        message: 'Cannot delete object without objectId',
      );
    }

    final restController = ParseRESTController.instance;

    try {
      await restController.request(
        'DELETE',
        'classes/$className/$objectId',
        options: options ?? const ParseRequestOptions(),
      );

      // Clear local state
      objectId = null;
      serverData.clear();
      localData.clear();
      _dirtyKeys.clear();
    } catch (e) {
      rethrow;
    }
  }

  /// Handle response after save
  @protected
  void handleSaveResponse(Map<String, dynamic> response) {
    // Update objectId if this was a new object
    if (response.containsKey('objectId')) {
      objectId = response['objectId'] as String;
    }

    // Update timestamps
    if (response.containsKey('createdAt')) {
      _createdAt = parseDate(response['createdAt'] as String);
    }
    if (response.containsKey('updatedAt')) {
      _updatedAt = parseDate(response['updatedAt'] as String);
    }

    // Move local data to server data
    localData.forEach((key, value) {
      serverData[key] = value;
    });
    localData.clear();
    _dirtyKeys.clear();
  }

  /// Handle response after fetch
  void _handleFetchResponse(Map<String, dynamic> response) {
    // Clear existing data
    serverData.clear();
    localData.clear();
    _dirtyKeys.clear();

    // Update timestamps
    if (response.containsKey('createdAt')) {
      _createdAt = parseDate(response['createdAt'] as String);
    }
    if (response.containsKey('updatedAt')) {
      _updatedAt = parseDate(response['updatedAt'] as String);
    }

    // Update ACL
    if (response.containsKey('ACL')) {
      _acl = ParseACL.fromJson(response['ACL'] as Map<String, dynamic>);
    }

    // Decode and store all fields
    response.forEach((key, value) {
      if (!['objectId', 'createdAt', 'updatedAt', 'ACL'].contains(key)) {
        serverData[key] = decode(value);
      }
    });
  }

  /// Convert to JSON (for encoding)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // Add objectId if present
    if (objectId != null) {
      json['objectId'] = objectId;
    }

    // Add timestamps
    if (_createdAt != null) {
      json['createdAt'] = formatDate(_createdAt!);
    }
    if (_updatedAt != null) {
      json['updatedAt'] = formatDate(_updatedAt!);
    }

    // Add ACL
    if (_acl != null) {
      json['ACL'] = _acl!.toJson();
    }

    // Add all data (local overrides server)
    serverData.forEach((key, value) {
      json[key] = encode(value);
    });
    localData.forEach((key, value) {
      json[key] = encode(value);
    });

    return json;
  }

  /// Convert to full JSON (including className and __type)
  Map<String, dynamic> toFullJson() {
    final json = toJson();
    json['__type'] = 'Object';
    json['className'] = className;
    return json;
  }

  /// Convert to pointer
  Map<String, dynamic> toPointer() {
    if (objectId == null && localId == null) {
      localId = 'local${generateUuid()}';
    }

    return {
      '__type': 'Pointer',
      'className': className,
      if (objectId != null) 'objectId': objectId,
      if (objectId == null && localId != null) '_localId': localId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParseObject &&
        other.className == className &&
        other.objectId == objectId &&
        objectId != null;
  }

  @override
  int get hashCode => className.hashCode ^ (objectId?.hashCode ?? 0);

  @override
  String toString() {
    return 'ParseObject(className: $className, objectId: $objectId)';
  }
}
