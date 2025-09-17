import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:path/path.dart' as path;
import 'http_server.dart';
import 'ws_server.dart';

/// Manages both HTTP and WebSocket servers in a unified way
class ServerManager {
  late HttpServer _httpServer;
  late WebSocketServer _wsServer;
  HttpServer? _combinedServer;
  
  final int port;
  final String webClientPath;

  ServerManager({
    this.port = 8080,
    this.webClientPath = 'web_client',
  }) {
    _httpServer = HttpServer(port: port, webClientPath: webClientPath);
    _wsServer = WebSocketServer(port: port);
  }

  /// Starts the combined HTTP and WebSocket server
  Future<void> start() async {
    if (_combinedServer != null) {
      throw Exception('Server is already running');
    }

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_router);

    _combinedServer = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      port,
    );

    print('Combined server started on port $port');
    print('HTTP server serving files from: $webClientPath');
    print('WebSocket server ready at: /ws');
  }

  /// Stops the server
  Future<void> stop() async {
    if (_combinedServer != null) {
      await _combinedServer!.close();
      _combinedServer = null;
      _wsServer.closeAllConnections();
      print('Server stopped');
    }
  }

  /// Checks if the server is running
  bool get isRunning => _combinedServer != null;

  /// Gets the server address
  String get address => _combinedServer?.address.address ?? '0.0.0.0';

  /// Gets the server port
  int get serverPort => _combinedServer?.port ?? port;

  /// Gets the full server URL
  String get url => 'http://$address:$serverPort';

  /// Router that handles both HTTP and WebSocket requests
  Future<Response> _router(Request request) async {
    final path = request.url.path;

    // WebSocket endpoint
    if (path == 'ws') {
      return _wsServer.handleWebSocketRequest(request);
    }

    // HTTP requests - serve static files
    return await _serveStaticFile(request);
  }

  /// Sets up WebSocket server callbacks
  void setupWebSocketCallbacks({
    Function(String)? onLogMessage,
    Function(int)? onConnectionCountChanged,
    Function(Map<String, dynamic>)? onMessageReceived,
  }) {
    _wsServer.onLogMessage = onLogMessage;
    _wsServer.onConnectionCountChanged = onConnectionCountChanged;
    _wsServer.onMessageReceived = onMessageReceived;
  }

  /// Gets the current connection count
  int get connectionCount => _wsServer.connectionCount;

  /// Gets all connection logs
  List<String> get logs => _wsServer.logs;

  /// Clears all logs
  void clearLogs() {
    _wsServer.clearLogs();
  }

  /// Broadcasts a message to all connected clients
  void broadcastMessage(Map<String, dynamic> message) {
    _wsServer.broadcastMessage(message);
  }

  /// Sends a ping to all connected clients
  void pingAllClients() {
    _wsServer.pingAllClients();
  }

  /// Serves static files from the web client directory
  Future<Response> _serveStaticFile(Request request) async {
    final requestPath = request.url.path;
    final filePath = requestPath.isEmpty ? 'index.html' : requestPath;

    // Security: prevent directory traversal
    if (filePath.contains('..') || filePath.startsWith('/')) {
      return Response.notFound('File not found');
    }

    final fullPath = path.join(webClientPath, filePath);
    final file = File(fullPath);
    
    if (!file.existsSync()) {
      return Response.notFound('File not found: $filePath');
    }

    try {
      final content = await file.readAsBytes();
      final contentType = _getContentType(filePath);

      return Response.ok(
        content,
        headers: {
          'Content-Type': contentType,
          'Cache-Control': 'no-cache',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error reading file: $e');
    }
  }

  /// Determines the MIME type for a file based on its extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    switch (extension) {
      case '.html':
        return 'text/html; charset=utf-8';
      case '.css':
        return 'text/css';
      case '.js':
        return 'application/javascript';
      case '.json':
        return 'application/json';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.ico':
        return 'image/x-icon';
      case '.woff':
        return 'font/woff';
      case '.woff2':
        return 'font/woff2';
      case '.ttf':
        return 'font/ttf';
      case '.eot':
        return 'application/vnd.ms-fontobject';
      default:
        return 'application/octet-stream';
    }
  }

  /// Gets server statistics
  Map<String, dynamic> getStats() {
    return {
      'isRunning': isRunning,
      'address': address,
      'port': serverPort,
      'url': url,
      'webClientPath': webClientPath,
      'connectionCount': connectionCount,
      'logCount': logs.length,
    };
  }
}
