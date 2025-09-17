import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:path/path.dart' as path;

/// HTTP server for serving static web client files
class HttpServer {
  HttpServer? _server;
  final int port;
  final String webClientPath;

  HttpServer({
    this.port = 8080,
    this.webClientPath = 'web_client',
  });

  /// Starts the HTTP server
  Future<void> start() async {
    if (_server != null) {
      throw Exception('Server is already running');
    }

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_router);

    _server = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      port,
    );

    print('HTTP server started on port $port');
    print('Serving files from: $webClientPath');
  }

  /// Stops the HTTP server
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      print('HTTP server stopped');
    }
  }

  /// Checks if the server is running
  bool get isRunning => _server != null;

  /// Gets the server address
  String get address => _server?.address.address ?? '0.0.0.0';

  /// Gets the server port
  int get serverPort => _server?.port ?? port;

  /// Gets the full server URL
  String get url => 'http://$address:$serverPort';

  /// Router for handling HTTP requests
  Future<Response> _router(Request request) async {
    final requestPath = request.url.path;

    // Security: prevent directory traversal
    if (requestPath.contains('..') || requestPath.startsWith('/')) {
      return Response.notFound('File not found');
    }

    // Determine file path
    final filePath = requestPath.isEmpty ? 'index.html' : requestPath;
    final fullPath = path.join(webClientPath, filePath);

    // Check if file exists
    final file = File(fullPath);
    if (!file.existsSync()) {
      return Response.notFound('File not found: $filePath');
    }

    try {
      // Read file content
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
    };
  }
}
