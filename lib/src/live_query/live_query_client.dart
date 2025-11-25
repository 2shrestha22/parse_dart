import 'dart:async';

/// Abstract WebSocket client for Live Query
///
/// The Parse SDK doesn't implement WebSocket connections directly.
/// Applications should provide their own WebSocket implementation.
///
/// Flutter/Web Example (using web_socket_channel):
/// ```dart
/// import 'package:web_socket_channel/web_socket_channel.dart';
///
/// class WebSocketClientImpl implements ParseWebSocketClient {
///   WebSocketChannel? _channel;
///   final _messageController = StreamController<String>.broadcast();
///
///   @override
///   Future<void> connect(String url) async {
///     _channel = WebSocketChannel.connect(Uri.parse(url));
///     _channel!.stream.listen(
///       (message) => _messageController.add(message.toString()),
///       onError: (error) => _messageController.addError(error),
///       onDone: () => _messageController.close(),
///     );
///   }
///
///   @override
///   void send(String message) {
///     _channel?.sink.add(message);
///   }
///
///   @override
///   Stream<String> get messages => _messageController.stream;
///
///   @override
///   Future<void> close() async {
///     await _channel?.sink.close();
///     await _messageController.close();
///   }
/// }
/// ```
///
/// Dart-only Example (using dart:io):
/// ```dart
/// import 'dart:io';
///
/// class DartWebSocketClient implements ParseWebSocketClient {
///   WebSocket? _socket;
///   final _messageController = StreamController<String>.broadcast();
///
///   @override
///   Future<void> connect(String url) async {
///     _socket = await WebSocket.connect(url);
///     _socket!.listen(
///       (message) => _messageController.add(message.toString()),
///       onError: (error) => _messageController.addError(error),
///       onDone: () => _messageController.close(),
///     );
///   }
///
///   @override
///   void send(String message) {
///     _socket?.add(message);
///   }
///
///   @override
///   Stream<String> get messages => _messageController.stream;
///
///   @override
///   Future<void> close() async {
///     await _socket?.close();
///     await _messageController.close();
///   }
/// }
/// ```
abstract class ParseWebSocketClient {
  /// Connect to WebSocket server
  Future<void> connect(String url);

  /// Send a message
  void send(String message);

  /// Stream of incoming messages
  Stream<String> get messages;

  /// Close the connection
  Future<void> close();
}

/// Factory for creating WebSocket clients
///
/// Applications must provide this factory to use Live Query
typedef ParseWebSocketClientFactory = ParseWebSocketClient Function();

/// Live Query client manager
class ParseLiveQueryClient {
  ParseLiveQueryClient._();

  static final ParseLiveQueryClient _instance = ParseLiveQueryClient._();
  static ParseLiveQueryClient get instance => _instance;

  ParseWebSocketClientFactory? _factory;

  /// Set the WebSocket client factory
  void setWebSocketFactory(ParseWebSocketClientFactory factory) {
    _factory = factory;
  }

  /// Check if Live Query is available
  bool get isAvailable => _factory != null;

  /// Create a new WebSocket client
  ParseWebSocketClient createClient() {
    if (_factory == null) {
      throw StateError(
        'WebSocket factory not set. Call Parse.setWebSocketFactory() first.',
      );
    }
    return _factory!();
  }
}
