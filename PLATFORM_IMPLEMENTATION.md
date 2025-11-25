# Parse Dart SDK - Platform Implementation Guide

This SDK is **pure Dart** with no Flutter or platform-specific dependencies. To use it in your application, you need to provide platform-specific implementations for:

1. **Storage** (for session persistence)
2. **WebSocket** (for Live Query)

---

## 1. Storage Implementation

The SDK requires a storage controller to persist user sessions and other data.

### Flutter Implementation (using shared_preferences)

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parse_dart/parse_dart.dart';

class FlutterStorageController implements ParseStorageController {
  final SharedPreferences _prefs;

  FlutterStorageController(this._prefs);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}

// Usage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  Parse.initialize(
    applicationId: 'YOUR_APP_ID',
    serverUrl: 'https://your-server.com/parse',
    clientKey: 'YOUR_CLIENT_KEY',
    storageController: FlutterStorageController(prefs),
  );
  
  runApp(MyApp());
}
```

### Dart Server/CLI Implementation (using file system)

```dart
import 'dart:io';
import 'package:parse_dart/parse_dart.dart';

class FileStorageController implements ParseStorageController {
  final Directory _storageDir;

  FileStorageController(String path) 
    : _storageDir = Directory(path) {
    if (!_storageDir.existsSync()) {
      _storageDir.createSync(recursive: true);
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    final file = File('${_storageDir.path}/$key');
    await file.writeAsString(value);
  }

  @override
  Future<String?> getString(String key) async {
    final file = File('${_storageDir.path}/$key');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  @override
  Future<void> remove(String key) async {
    final file = File('${_storageDir.path}/$key');
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clear() async {
    await for (final entity in _storageDir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }
}

// Usage
void main() {
  Parse.initialize(
    applicationId: 'YOUR_APP_ID',
    serverUrl: 'https://your-server.com/parse',
    clientKey: 'YOUR_CLIENT_KEY',
    storageController: FileStorageController('.parse_storage'),
  );
}
```

### Alternative: Hive Storage (Flutter/Dart)

```dart
import 'package:hive/hive.dart';
import 'package:parse_dart/parse_dart.dart';

class HiveStorageController implements ParseStorageController {
  final Box _box;

  HiveStorageController(this._box);

  static Future<HiveStorageController> create() async {
    await Hive.initFlutter(); // Or Hive.init() for non-Flutter
    final box = await Hive.openBox('parse_storage');
    return HiveStorageController(box);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _box.put(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    return _box.get(key) as String?;
  }

  @override
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

// Usage
void main() async {
  final storage = await HiveStorageController.create();
  
  Parse.initialize(
    applicationId: 'YOUR_APP_ID',
    serverUrl: 'https://your-server.com/parse',
    storageController: storage,
  );
}
```

---

## 2. WebSocket Implementation (for Live Query)

### Flutter/Web Implementation (using web_socket_channel)

```dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:parse_dart/parse_dart.dart';
import 'dart:async';

class WebSocketClientImpl implements ParseWebSocketClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<String>.broadcast();

  @override
  Future<void> connect(String url) async {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen(
      (message) => _messageController.add(message.toString()),
      onError: (error) => _messageController.addError(error),
      onDone: () => _messageController.close(),
    );
  }

  @override
  void send(String message) {
    _channel?.sink.add(message);
  }

  @override
  Stream<String> get messages => _messageController.stream;

  @override
  Future<void> close() async {
    await _channel?.sink.close();
    await _messageController.close();
  }
}

// Usage
Parse.initialize(
  applicationId: 'YOUR_APP_ID',
  serverUrl: 'https://your-server.com/parse',
  webSocketFactory: () => WebSocketClientImpl(),
);
```

### Dart Server/CLI Implementation (using dart:io)

```dart
import 'dart:io';
import 'dart:async';
import 'package:parse_dart/parse_dart.dart';

class DartWebSocketClient implements ParseWebSocketClient {
  WebSocket? _socket;
  final _messageController = StreamController<String>.broadcast();

  @override
  Future<void> connect(String url) async {
    _socket = await WebSocket.connect(url);
    _socket!.listen(
      (message) => _messageController.add(message.toString()),
      onError: (error) => _messageController.addError(error),
      onDone: () => _messageController.close(),
    );
  }

  @override
  void send(String message) {
    _socket?.add(message);
  }

  @override
  Stream<String> get messages => _messageController.stream;

  @override
  Future<void> close() async {
    await _socket?.close();
    await _messageController.close();
  }
}

// Usage
Parse.initialize(
  applicationId: 'YOUR_APP_ID',
  serverUrl: 'https://your-server.com/parse',
  webSocketFactory: () => DartWebSocketClient(),
);
```

---

## Complete Example (Flutter)

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:parse_dart/parse_dart.dart';
import 'dart:async';

// Storage implementation
class FlutterStorageController implements ParseStorageController {
  final SharedPreferences _prefs;
  FlutterStorageController(this._prefs);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> remove(String key) async => await _prefs.remove(key);

  @override
  Future<void> clear() async => await _prefs.clear();
}

// WebSocket implementation
class WebSocketClientImpl implements ParseWebSocketClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<String>.broadcast();

  @override
  Future<void> connect(String url) async {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen(
      (message) => _messageController.add(message.toString()),
      onError: (error) => _messageController.addError(error),
      onDone: () => _messageController.close(),
    );
  }

  @override
  void send(String message) => _channel?.sink.add(message);

  @override
  Stream<String> get messages => _messageController.stream;

  @override
  Future<void> close() async {
    await _channel?.sink.close();
    await _messageController.close();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final prefs = await SharedPreferences.getInstance();

  // Initialize Parse
  Parse.initialize(
    applicationId: 'YOUR_APP_ID',
    serverUrl: 'https://your-server.com/parse',
    clientKey: 'YOUR_CLIENT_KEY',
    storageController: FlutterStorageController(prefs),
    webSocketFactory: () => WebSocketClientImpl(),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Parse Dart SDK')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // Test Parse
              final user = ParseUser()
                ..username = 'testuser'
                ..password = 'password123'
                ..email = 'test@example.com';

              try {
                await user.signUp();
                print('User signed up: ${user.objectId}');
              } catch (e) {
                print('Error: $e');
              }
            },
            child: Text('Test Parse'),
          ),
        ),
      ),
    );
  }
}
```

---

## Why This Architecture?

1. **Pure Dart Core**: The SDK remains platform-agnostic and can run anywhere Dart runs
2. **Flexibility**: You choose the storage and WebSocket implementations that best fit your needs
3. **No Bloat**: Your app only includes the dependencies you actually use
4. **Testability**: Easy to mock storage and WebSocket for testing
5. **Future-Proof**: New platforms (e.g., Dart on embedded systems) can provide their own implementations

---

## Optional Features

Both storage and WebSocket are **optional**:

- **Without Storage**: The SDK works but won't persist user sessions (users logout on app restart)
- **Without WebSocket**: The SDK works but Live Query won't be available

```dart
// Minimal initialization (no persistence, no Live Query)
Parse.initialize(
  applicationId: 'YOUR_APP_ID',
  serverUrl: 'https://your-server.com/parse',
);
```
