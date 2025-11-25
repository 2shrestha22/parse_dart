import 'package:equatable/equatable.dart';

/// Access Control List for Parse objects
///
/// Controls read and write permissions for objects.
///
/// Example:
/// ```dart
/// final acl = ParseACL()
///   ..setPublicReadAccess(true)
///   ..setPublicWriteAccess(false)
///   ..setReadAccess('userId123', true)
///   ..setWriteAccess('userId123', true);
///
/// object.setACL(acl);
/// ```
class ParseACL extends Equatable {
  final Map<String, Map<String, bool>> _permissions = {};

  ParseACL();

  /// Create ACL from JSON
  factory ParseACL.fromJson(Map<String, dynamic> json) {
    final acl = ParseACL();
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        acl._permissions[key] = Map<String, bool>.from(value);
      }
    });
    return acl;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(_permissions);
  }

  /// Set read access for a specific user
  void setReadAccess(String userId, bool allowed) {
    _setAccess(userId, 'read', allowed);
  }

  /// Set write access for a specific user
  void setWriteAccess(String userId, bool allowed) {
    _setAccess(userId, 'write', allowed);
  }

  /// Get read access for a specific user
  bool getReadAccess(String userId) {
    return _permissions[userId]?['read'] ?? false;
  }

  /// Get write access for a specific user
  bool getWriteAccess(String userId) {
    return _permissions[userId]?['write'] ?? false;
  }

  /// Set public read access
  void setPublicReadAccess(bool allowed) {
    _setAccess('*', 'read', allowed);
  }

  /// Set public write access
  void setPublicWriteAccess(bool allowed) {
    _setAccess('*', 'write', allowed);
  }

  /// Get public read access
  bool getPublicReadAccess() {
    return _permissions['*']?['read'] ?? false;
  }

  /// Get public write access
  bool getPublicWriteAccess() {
    return _permissions['*']?['write'] ?? false;
  }

  /// Set role read access
  void setRoleReadAccess(String roleName, bool allowed) {
    _setAccess('role:$roleName', 'read', allowed);
  }

  /// Set role write access
  void setRoleWriteAccess(String roleName, bool allowed) {
    _setAccess('role:$roleName', 'write', allowed);
  }

  /// Get role read access
  bool getRoleReadAccess(String roleName) {
    return _permissions['role:$roleName']?['read'] ?? false;
  }

  /// Get role write access
  bool getRoleWriteAccess(String roleName) {
    return _permissions['role:$roleName']?['write'] ?? false;
  }

  void _setAccess(String key, String accessType, bool allowed) {
    if (!_permissions.containsKey(key)) {
      _permissions[key] = {};
    }
    if (allowed) {
      _permissions[key]![accessType] = true;
    } else {
      _permissions[key]!.remove(accessType);
      if (_permissions[key]!.isEmpty) {
        _permissions.remove(key);
      }
    }
  }

  @override
  List<Object?> get props => [_permissions];

  @override
  String toString() => 'ParseACL($_permissions)';
}
