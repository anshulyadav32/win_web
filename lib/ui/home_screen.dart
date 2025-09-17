import 'package:flutter/material.dart';
import '../server/ip_utils.dart';
import '../server/server_manager.dart';

/// Home screen widget that displays server status and controls
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ServerManager _serverManager;
  
  String _localIP = 'Detecting...';
  bool _isServerRunning = false;
  int _connectedClients = 0;
  List<String> _connectionLogs = [];

  @override
  void initState() {
    super.initState();
    _initializeServer();
    _detectLocalIP();
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  void _initializeServer() {
    _serverManager = ServerManager();
    
    // Set up server callbacks
    _serverManager.setupWebSocketCallbacks(
      onLogMessage: (message) {
        setState(() {
          _connectionLogs.insert(0, message);
          if (_connectionLogs.length > 50) {
            _connectionLogs.removeLast();
          }
        });
      },
      onConnectionCountChanged: (count) {
        setState(() {
          _connectedClients = count;
        });
      },
      onMessageReceived: (message) {
        // Handle received messages here
        // This will be expanded in Phase 2 for actual mouse control
      },
    );
  }

  Future<void> _detectLocalIP() async {
    final ip = await IpUtils.detectLocalIP();
    setState(() {
      _localIP = ip;
    });
  }

  Future<void> _startServer() async {
    if (_isServerRunning) return;

    try {
      await _serverManager.start();
      setState(() {
        _isServerRunning = true;
      });
      
      _addLog('Server started on $_localIP:${_serverManager.serverPort}');
      _addLog('Web client available at: ${_serverManager.url}');
    } catch (e) {
      _addLog('Failed to start server: $e');
    }
  }

  Future<void> _stopServer() async {
    if (_isServerRunning) {
      await _serverManager.stop();
      setState(() {
        _isServerRunning = false;
        _connectedClients = 0;
      });
      _addLog('Server stopped');
    }
  }

  void _addLog(String message) {
    setState(() {
      _connectionLogs.insert(0, message);
      if (_connectionLogs.length > 50) {
        _connectionLogs.removeLast();
      }
    });
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
            _buildServerStatusCard(),
            const SizedBox(height: 16),
            
            // Connection Logs
            Expanded(
              child: _buildConnectionLogsCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatusCard() {
    return Card(
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
            _buildInfoRow('Port:', _serverManager.serverPort.toString()),
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
                  _serverManager.url,
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
    );
  }

  Widget _buildConnectionLogsCard() {
    return Card(
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
