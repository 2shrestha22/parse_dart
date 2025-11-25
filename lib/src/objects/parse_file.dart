import 'dart:convert';
import 'dart:typed_data';

import '../controllers/rest_controller.dart';
import '../core/parse_error.dart';

/// Represents a file stored in Parse Server
///
/// Example:
/// ```dart
/// // From bytes
/// final file = ParseFile.fromBytes('profile.jpg', imageBytes, mimeType: 'image/jpeg');
/// await file.save();
/// print('URL: ${file.url}');
///
/// // From base64
/// final file = ParseFile.fromBase64('doc.pdf', base64String, mimeType: 'application/pdf');
/// await file.save();
/// ```
class ParseFile {
  final String name;
  final Uint8List? _bytes;
  final String? _base64;
  final String? mimeType;

  String? _url;
  bool _saved = false;

  ParseFile._(
    this.name, {
    Uint8List? bytes,
    String? base64,
    this.mimeType,
    String? url,
  })  : _bytes = bytes,
        _base64 = base64,
        _url = url,
        _saved = url != null;

  /// Create a file from bytes
  factory ParseFile.fromBytes(
    String name,
    Uint8List bytes, {
    String? mimeType,
  }) {
    return ParseFile._(name, bytes: bytes, mimeType: mimeType);
  }

  /// Create a file from base64 string
  factory ParseFile.fromBase64(
    String name,
    String base64, {
    String? mimeType,
  }) {
    return ParseFile._(name, base64: base64, mimeType: mimeType);
  }

  /// Create from JSON (for decoding)
  factory ParseFile.fromJson(Map<String, dynamic> json) {
    return ParseFile._(
      json['name'] as String,
      url: json['url'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '__type': 'File',
      'name': name,
      if (_url != null) 'url': _url,
    };
  }

  /// Get the file URL (available after save)
  String? get url => _url;

  /// Check if file is saved
  bool get isSaved => _saved;

  /// Save the file to Parse Server
  Future<void> save({
    void Function(double progress)? onProgress,
    ParseRequestOptions? options,
  }) async {
    if (_saved) return; // Already saved

    if (_bytes == null && _base64 == null) {
      throw const ParseException(
        code: ParseErrorCode.unsavedFileError,
        message: 'Cannot save file without data',
      );
    }

    final restController = ParseRESTController.instance;

    // Prepare file data
    final Map<String, dynamic> body;
    if (_base64 != null) {
      body = {
        'base64': _base64,
        '_ContentType': mimeType ?? 'application/octet-stream',
      };
    } else {
      // Convert bytes to base64 string
      final base64Data = base64Encode(_bytes!);
      body = {
        'base64': base64Data,
        '_ContentType': mimeType ?? 'application/octet-stream',
      };
    }

    try {
      final response = await restController.request(
        'POST',
        'files/$name',
        data: body,
        options: options ?? const ParseRequestOptions(),
      );

      _url = response.data['url'] as String?;
      _saved = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete the file from Parse Server
  Future<void> delete({ParseRequestOptions? options}) async {
    if (!_saved || _url == null) {
      throw const ParseException(
        code: ParseErrorCode.fileDeleteError,
        message: 'Cannot delete unsaved file',
      );
    }

    final restController = ParseRESTController.instance;

    try {
      await restController.request(
        'DELETE',
        'files/$name',
        options: options ?? const ParseRequestOptions(useMasterKey: true),
      );

      _saved = false;
      _url = null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  String toString() => 'ParseFile(name: $name, url: $_url)';
}
