import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'message_protocol.dart';

/// WebSocket server for handling real-time communication with clients
class WebSocketServer {
  final int port;
  final List<WebSocketChannel> _connections = [];
  final List<String> _connectionLogs = [];
  int _connectionIdCounter = 0;

  // Callbacks for different events
  Function(String)? onLogMessage;
  Function(int)? onConnectionCountChanged;
  Function(Map<String, dynamic>)? onMessageReceived;

  WebSocketServer({this.port = 8080});

  /// Creates a WebSocket handler for the given request
  Response handleWebSocketRequest(Request request) {
    return webSocketHandler((WebSocketChannel channel) {
      _handleNewConnection(channel);
    })(request);
  }

  /// Handles a new WebSocket connection
  void _handleNewConnection(WebSocketChannel channel) {
    final connectionId = ++_connectionIdCounter;
    _connections.add(channel);
    
    _addLog('Client connected (ID: $connectionId, Total: ${_connections.length})');
    onConnectionCountChanged?.call(_connections.length);

    // Listen for messages from this client
    channel.stream.listen(
      (message) => _handleMessage(channel, message, connectionId),
      onDone: () => _handleDisconnection(channel, connectionId),
      onError: (error) => _handleError(channel, error, connectionId),
    );
  }

  /// Handles incoming WebSocket messages
  void _handleMessage(WebSocketChannel channel, dynamic message, int connectionId) {
    try {
      final data = jsonDecode(message);
      
      if (MessageProtocol.isValidMessage(data)) {
        final description = MessageProtocol.getMessageDescription(data);
        _addLog('Client $connectionId: $description');
        
        // Call the message received callback
        onMessageReceived?.call(data);
        
        // Handle specific message types
        _processMessage(data, connectionId);
      } else {
        _addLog('Client $connectionId: Invalid message format');
      }
    } catch (e) {
      _addLog('Client $connectionId: Error parsing message: $e');
    }
  }

  /// Processes specific message types
  void _processMessage(Map<String, dynamic> message, int connectionId) {
    final type = message['type'] as String?;
    
    switch (type) {
      case MessageProtocol.connectionPing:
        // Respond to ping with pong
        _sendToConnection(connectionId, MessageProtocol.createPongMessage());
        break;
      
      case MessageProtocol.pointerMove:
        // Log pointer movement with more detail
        final dx = message['dx'] ?? 0;
        final dy = message['dy'] ?? 0;
        if (dx != 0 || dy != 0) {
          _addLog('Client $connectionId: Mouse move (dx: $dx, dy: $dy)');
        }
        break;
      
      case MessageProtocol.pointerClick:
        // Log click events
        final button = message['button'] ?? 'unknown';
        final pressed = message['pressed'] ?? false;
        _addLog('Client $connectionId: ${button} button ${pressed ? 'pressed' : 'released'}');
        break;
      
      case MessageProtocol.pointerScroll:
        // Log scroll events
        final deltaX = message['deltaX'] ?? 0;
        final deltaY = message['deltaY'] ?? 0;
        _addLog('Client $connectionId: Scroll (deltaX: $deltaX, deltaY: $deltaY)');
        break;
      
      case MessageProtocol.keyPress:
      case MessageProtocol.keyRelease:
        // Log key events
        final key = message['key'] ?? 'unknown';
        final pressed = message['pressed'] ?? false;
        _addLog('Client $connectionId: Key ${pressed ? 'press' : 'release'}: $key');
        break;
    }
  }

  /// Handles WebSocket disconnection
  void _handleDisconnection(WebSocketChannel channel, int connectionId) {
    _connections.remove(channel);
    _addLog('Client disconnected (ID: $connectionId, Total: ${_connections.length})');
    onConnectionCountChanged?.call(_connections.length);
  }

  /// Handles WebSocket errors
  void _handleError(WebSocketChannel channel, dynamic error, int connectionId) {
    _addLog('Client $connectionId: WebSocket error: $error');
    _connections.remove(channel);
    onConnectionCountChanged?.call(_connections.length);
  }

  /// Sends a message to a specific connection
  void _sendToConnection(int connectionId, Map<String, dynamic> message) {
    if (connectionId > 0 && connectionId <= _connections.length) {
      try {
        final channel = _connections[connectionId - 1];
        channel.sink.add(jsonEncode(message));
      } catch (e) {
        _addLog('Error sending message to client $connectionId: $e');
      }
    }
  }

  /// Broadcasts a message to all connected clients
  void broadcastMessage(Map<String, dynamic> message) {
    final messageJson = jsonEncode(message);
    
    for (int i = 0; i < _connections.length; i++) {
      try {
        _connections[i].sink.add(messageJson);
      } catch (e) {
        _addLog('Error broadcasting to client ${i + 1}: $e');
        _connections.removeAt(i);
        i--; // Adjust index after removal
      }
    }
    
    onConnectionCountChanged?.call(_connections.length);
  }

  /// Sends a ping to all connected clients
  void pingAllClients() {
    broadcastMessage(MessageProtocol.createPingMessage());
  }

  /// Closes all connections
  void closeAllConnections() {
    for (final channel in _connections) {
      try {
        channel.sink.close();
      } catch (e) {
        // Ignore errors when closing
      }
    }
    _connections.clear();
    _addLog('All connections closed');
    onConnectionCountChanged?.call(0);
  }

  /// Adds a log message
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '$timestamp - $message';
    _connectionLogs.insert(0, logEntry);
    
    // Keep only the last 100 log entries
    if (_connectionLogs.length > 100) {
      _connectionLogs.removeLast();
    }
    
    onLogMessage?.call(logEntry);
  }

  /// Gets the current connection count
  int get connectionCount => _connections.length;

  /// Gets all connection logs
  List<String> get logs => List.unmodifiable(_connectionLogs);

  /// Clears all logs
  void clearLogs() {
    _connectionLogs.clear();
  }

  /// Gets server statistics
  Map<String, dynamic> getStats() {
    return {
      'connectionCount': connectionCount,
      'logCount': _connectionLogs.length,
      'port': port,
    };
  }
}
