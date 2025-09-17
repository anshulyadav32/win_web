import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const RemoteMouseApp());
}

class RemoteMouseApp extends StatelessWidget {
  const RemoteMouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Mouse Server',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RemoteMouseHomePage(),
    );
  }
}

class RemoteMouseHomePage extends StatefulWidget {
  const RemoteMouseHomePage({super.key});

  @override
  State<RemoteMouseHomePage> createState() => _RemoteMouseHomePageState();
}

class _RemoteMouseHomePageState extends State<RemoteMouseHomePage> {
  HttpServer? _server;
  String _localIP = 'Detecting...';
  int _port = 8080;
  bool _isServerRunning = false;
  List<String> _connectionLogs = [];
  int _connectedClients = 0;

  @override
  void initState() {
    super.initState();
    _detectLocalIP();
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  Future<void> _detectLocalIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              _localIP = addr.address;
            });
            return;
          }
        }
      }
    } catch (e) {
      setState(() {
        _localIP = 'Error detecting IP';
      });
    }
  }

  Future<void> _startServer() async {
    if (_isServerRunning) return;

    try {
      // Create the HTTP server
      _server = await shelf_io.serve(
        _createHandler(),
        InternetAddress.anyIPv4,
        _port,
      );

      setState(() {
        _isServerRunning = true;
      });

      _addLog('Server started on $_localIP:$_port');
      _addLog('Web client available at: http://$_localIP:$_port');

    } catch (e) {
      _addLog('Failed to start server: $e');
    }
  }

  Future<void> _stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      setState(() {
        _isServerRunning = false;
        _connectedClients = 0;
      });
      _addLog('Server stopped');
    }
  }

  void _addLog(String message) {
    setState(() {
      _connectionLogs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_connectionLogs.length > 50) {
        _connectionLogs.removeLast();
      }
    });
  }

  Handler _createHandler() {
    final pipeline = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_router);

    return pipeline;
  }

  Future<Response> _router(Request request) async {
    final path = request.url.path;

    // WebSocket endpoint
    if (path == 'ws') {
      return await webSocketHandler((WebSocketChannel channel) {
        _handleWebSocketConnection(channel);
      })(request);
    }

    // Serve static files from web_client directory
    return _serveStaticFile(request);
  }

  void _handleWebSocketConnection(WebSocketChannel channel) {
    setState(() {
      _connectedClients++;
    });
    _addLog('Client connected (Total: $_connectedClients)');

    channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          _addLog('Received: ${data.toString()}');
          
          // Log specific pointer movements
          if (data['type'] == 'pointer_move') {
            final dx = data['dx'] ?? 0;
            final dy = data['dy'] ?? 0;
            _addLog('Pointer move: dx=$dx, dy=$dy');
          }
        } catch (e) {
          _addLog('Invalid JSON received: $message');
        }
      },
      onDone: () {
        setState(() {
          _connectedClients--;
        });
        _addLog('Client disconnected (Total: $_connectedClients)');
      },
      onError: (error) {
        _addLog('WebSocket error: $error');
      },
    );
  }

  Response _serveStaticFile(Request request) {
    final path = request.url.path;
    final filePath = path.isEmpty ? 'index.html' : path;

    // Security: prevent directory traversal
    if (filePath.contains('..') || filePath.startsWith('/')) {
      return Response.notFound('File not found');
    }

    final file = File('web_client/$filePath');
    
    if (!file.existsSync()) {
      return Response.notFound('File not found');
    }

    final content = file.readAsBytesSync();
    final contentType = _getContentType(filePath);

    return Response.ok(
      content,
      headers: {
        'Content-Type': contentType,
        'Cache-Control': 'no-cache',
      },
    );
  }

  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'html':
        return 'text/html; charset=utf-8';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'json':
        return 'application/json';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Mouse Server'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
            onPressed: _isServerRunning ? _stopServer : _startServer,
            tooltip: _isServerRunning ? 'Stop Server' : 'Start Server',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isServerRunning ? Icons.check_circle : Icons.error,
                          color: _isServerRunning ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isServerRunning ? 'Server Running' : 'Server Stopped',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Local IP:', _localIP),
                    _buildInfoRow('Port:', _port.toString()),
                    _buildInfoRow('Connected Clients:', _connectedClients.toString()),
                    if (_isServerRunning) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          'http://$_localIP:$_port',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Connection Logs
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history),
                          const SizedBox(width: 8),
                          Text(
                            'Connection Logs',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _connectionLogs.clear();
                              });
                            },
                            tooltip: 'Clear Logs',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _connectionLogs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No logs yet. Start the server to see connection activity.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _connectionLogs.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      _connectionLogs[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
