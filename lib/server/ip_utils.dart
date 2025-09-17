import 'dart:io';

/// Utility functions for network and IP address operations
class IpUtils {
  /// Detects the local IPv4 address for the primary network interface
  /// Returns the first non-loopback IPv4 address found
  static Future<String> detectLocalIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      return 'Unable to detect IP';
    } catch (e) {
      return 'Error detecting IP: $e';
    }
  }

  /// Gets all available network interfaces with their IP addresses
  static Future<List<NetworkInterfaceInfo>> getAllNetworkInterfaces() async {
    final interfaces = <NetworkInterfaceInfo>[];
    
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            interfaces.add(NetworkInterfaceInfo(
              name: interface.name,
              address: addr.address,
              isLoopback: addr.isLoopback,
            ));
          }
        }
      }
    } catch (e) {
      // Return empty list on error
    }
    
    return interfaces;
  }

  /// Validates if an IP address is in a valid format
  static bool isValidIP(String ip) {
    try {
      final address = InternetAddress(ip);
      return address.type == InternetAddressType.IPv4 && !address.isLoopback;
    } catch (e) {
      return false;
    }
  }

  /// Gets the primary network interface name
  static Future<String> getPrimaryInterfaceName() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return interface.name;
          }
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Error';
    }
  }

  /// Checks if the server can bind to a specific address and port
  static Future<bool> canBindToAddress(String address, int port) async {
    try {
      final server = await ServerSocket.bind(address, port);
      await server.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets a user-friendly network status message
  static Future<String> getNetworkStatus() async {
    final ip = await detectLocalIP();
    final interfaceName = await getPrimaryInterfaceName();
    
    if (ip.startsWith('Error') || ip.startsWith('Unable')) {
      return 'Network not available';
    }
    
    return 'Connected via $interfaceName ($ip)';
  }
}

/// Data class for network interface information
class NetworkInterfaceInfo {
  final String name;
  final String address;
  final bool isLoopback;

  NetworkInterfaceInfo({
    required this.name,
    required this.address,
    required this.isLoopback,
  });

  @override
  String toString() {
    return '$name: $address';
  }
}
