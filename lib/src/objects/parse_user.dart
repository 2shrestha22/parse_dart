import 'dart:convert';

import '../controllers/rest_controller.dart';
import '../core/parse_error.dart';
import '../storage/storage_controller.dart';
import 'parse_object.dart';

/// Represents a Parse user with authentication
///
/// Example:
/// ```dart
/// // Sign up
/// final user = ParseUser()
///   ..username = 'johndoe'
///   ..password = 'secure123'
///   ..email = 'john@example.com';
/// await user.signUp();
///
/// // Login
/// final user = await ParseUser.login('johndoe', 'secure123');
///
/// // Current user
/// final current = await ParseUser.currentUser();
/// ```
class ParseUser extends ParseObject {
  static ParseUser? _currentUser;
  // Storage key for current user (will be used when storage persistence is implemented)
  // ignore: unused_field
  static const String _currentUserKey = 'ParseUser_currentUser';

  ParseUser() : super('_User');

  /// Create from JSON
  factory ParseUser.fromJson(Map<String, dynamic> json) {
    final user = ParseUser();
    // Use ParseObject's fromJson logic
    final tempObject = ParseObject.fromJson('_User', json);
    user.objectId = tempObject.objectId;
    user.createdAt = tempObject.createdAt;
    user.updatedAt = tempObject.updatedAt;
    user.aclValue = tempObject.acl;

    // Copy server data
    tempObject.serverData.forEach((key, value) {
      user.serverData[key] = value;
    });

    return user;
  }

  // User-specific getters/setters

  /// Username
  String? get username => get<String>('username');
  set username(String? value) => set('username', value);

  /// Email
  String? get email => get<String>('email');
  set email(String? value) => set('email', value);

  /// Password (write-only for security)
  set password(String value) => set('password', value);

  /// Session token
  String? get sessionToken => get<String>('sessionToken');

  /// Email verified
  bool? get emailVerified => get<bool>('emailVerified');

  /// Sign up a new user
  Future<void> signUp({ParseRequestOptions? options}) async {
    if (username == null || username!.isEmpty) {
      throw const ParseException(
        code: ParseErrorCode.usernameMissing,
        message: 'Username is required',
      );
    }

    final password = localData['password'];
    if (password == null) {
      throw const ParseException(
        code: ParseErrorCode.passwordMissing,
        message: 'Password is required',
      );
    }

    final restController = ParseRESTController.instance;

    // Build signup data
    final data = <String, dynamic>{
      'username': username,
      'password': password,
    };

    if (email != null) {
      data['email'] = email;
    }

    // Add any other fields
    localData.forEach((key, value) {
      if (key != 'username' && key != 'password' && key != 'email') {
        data[key] = value;
      }
    });

    try {
      final response = await restController.request(
        'POST',
        'users',
        data: data,
        options: options ?? const ParseRequestOptions(),
      );

      handleSaveResponse(response.data);

      // Set as current user
      _currentUser = this;
      await _saveCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  /// Login with username and password
  static Future<ParseUser> login(
    String username,
    String password, {
    ParseRequestOptions? options,
  }) async {
    final restController = ParseRESTController.instance;

    try {
      final response = await restController.request(
        'POST',
        'login',
        data: {
          'username': username,
          'password': password,
        },
        options: options ?? const ParseRequestOptions(),
      );

      final user = ParseUser.fromJson(response.data);
      _currentUser = user;
      await _saveCurrentUser();

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout current user
  static Future<void> logout() async {
    _currentUser = null;
    await ParseStorageManager.instance.remove(_currentUserKey);
  }

  /// Get current user
  static Future<ParseUser?> currentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    // Try to load from storage
    final stored = await ParseStorageManager.instance.getString(
      _currentUserKey,
    );
    if (stored != null && stored.isNotEmpty) {
      try {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        _currentUser = ParseUser.fromJson(json);
      } catch (e) {
        // If parsing fails, clear the invalid data
        await ParseStorageManager.instance.remove(_currentUserKey);
      }
    }

    return _currentUser;
  }

  /// Check if there's a current user
  static bool get isLoggedIn => _currentUser != null;

  /// Request password reset
  static Future<void> requestPasswordReset(String email) async {
    final restController = ParseRESTController.instance;

    try {
      await restController.request(
        'POST',
        'requestPasswordReset',
        data: {'email': email},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Verify email
  static Future<void> verifyEmail(String email) async {
    // This is typically handled server-side
    throw UnimplementedError('Email verification is handled server-side');
  }

  /// Save current user to storage
  static Future<void> _saveCurrentUser() async {
    if (_currentUser == null) {
      await ParseStorageManager.instance.remove(_currentUserKey);
      return;
    }

    // Only save if storage is available
    if (!ParseStorageManager.instance.isAvailable) {
      return;
    }

    try {
      final json = jsonEncode(_currentUser!.toJson());
      await ParseStorageManager.instance.setString(_currentUserKey, json);
    } catch (e) {
      // Silently fail if storage fails
      // This allows the app to continue working without persistence
    }
  }

  /// Become user with session token
  static Future<ParseUser> become(String sessionToken) async {
    final restController = ParseRESTController.instance;

    try {
      final response = await restController.request(
        'GET',
        'users/me',
        options: ParseRequestOptions(sessionToken: sessionToken),
      );

      final user = ParseUser.fromJson(response.data);
      _currentUser = user;
      await _saveCurrentUser();

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> save({ParseRequestOptions? options}) async {
    // If this is the current user, update the cached version
    if (this == _currentUser) {
      await super.save(options: options);
      await _saveCurrentUser();
    } else {
      await super.save(options: options);
    }
  }
}
