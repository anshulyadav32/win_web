/// Message protocol definitions for Remote Mouse communication
/// 
/// This file defines the JSON message formats used between the web client
/// and the Flutter server for various input events.

class MessageProtocol {
  // Message types
  static const String pointerMove = 'pointer_move';
  static const String pointerClick = 'pointer_click';
  static const String pointerScroll = 'pointer_scroll';
  static const String keyPress = 'key_press';
  static const String keyRelease = 'key_release';
  static const String connectionPing = 'ping';
  static const String connectionPong = 'pong';

  /// Creates a pointer movement message
  static Map<String, dynamic> createPointerMoveMessage({
    required int dx,
    required int dy,
  }) {
    return {
      'type': pointerMove,
      'dx': dx,
      'dy': dy,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Creates a pointer click message
  static Map<String, dynamic> createPointerClickMessage({
    required String button, // 'left', 'right', 'middle'
    required bool isPressed,
  }) {
    return {
      'type': pointerClick,
      'button': button,
      'pressed': isPressed,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Creates a pointer scroll message
  static Map<String, dynamic> createPointerScrollMessage({
    required int deltaX,
    required int deltaY,
  }) {
    return {
      'type': pointerScroll,
      'deltaX': deltaX,
      'deltaY': deltaY,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Creates a key press/release message
  static Map<String, dynamic> createKeyMessage({
    required String key,
    required bool isPressed,
  }) {
    return {
      'type': isPressed ? keyPress : keyRelease,
      'key': key,
      'pressed': isPressed,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Creates a ping message for connection testing
  static Map<String, dynamic> createPingMessage() {
    return {
      'type': connectionPing,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Creates a pong response message
  static Map<String, dynamic> createPongMessage() {
    return {
      'type': connectionPong,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Validates if a message has the required structure
  static bool isValidMessage(Map<String, dynamic> message) {
    return message.containsKey('type') && 
           message.containsKey('timestamp') &&
           message['type'] is String &&
           message['timestamp'] is int;
  }

  /// Gets a human-readable description of a message
  static String getMessageDescription(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    
    switch (type) {
      case pointerMove:
        final dx = message['dx'] ?? 0;
        final dy = message['dy'] ?? 0;
        return 'Pointer move: dx=$dx, dy=$dy';
      
      case pointerClick:
        final button = message['button'] ?? 'unknown';
        final pressed = message['pressed'] ?? false;
        return 'Pointer click: $button button ${pressed ? 'pressed' : 'released'}';
      
      case pointerScroll:
        final deltaX = message['deltaX'] ?? 0;
        final deltaY = message['deltaY'] ?? 0;
        return 'Pointer scroll: deltaX=$deltaX, deltaY=$deltaY';
      
      case keyPress:
      case keyRelease:
        final key = message['key'] ?? 'unknown';
        final pressed = message['pressed'] ?? false;
        return 'Key ${pressed ? 'press' : 'release'}: $key';
      
      case connectionPing:
        return 'Connection ping';
      
      case connectionPong:
        return 'Connection pong';
      
      default:
        return 'Unknown message type: $type';
    }
  }
}
