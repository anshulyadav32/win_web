# 🏗️ Remote Mouse - Architecture Guide

## 📂 Project Structure

```
win_web/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── server/                      # Server components
│   │   ├── server_manager.dart      # Unified server management
│   │   ├── http_server.dart         # HTTP server for static files
│   │   ├── ws_server.dart           # WebSocket server
│   │   ├── ip_utils.dart            # Network utilities
│   │   └── message_protocol.dart    # Message format definitions
│   └── ui/                          # UI components
│       └── home_screen.dart         # Main server UI
├── web_client/                      # Web client files
│   ├── index.html                   # Client HTML
│   ├── style.css                    # Client styling
│   └── main.js                      # Client JavaScript
└── pubspec.yaml                     # Dependencies
```

---

## 🔧 Component Overview

### 📱 `lib/main.dart`
- **Purpose**: Application entry point
- **Responsibilities**: 
  - Initialize Flutter app
  - Set up Material theme
  - Launch home screen
- **Dependencies**: `ui/home_screen.dart`

### 🖥️ `lib/ui/home_screen.dart`
- **Purpose**: Main server UI
- **Responsibilities**:
  - Display server status and controls
  - Show connection logs
  - Manage server start/stop
  - Display local IP and connection URL
- **Dependencies**: `server/server_manager.dart`, `server/ip_utils.dart`

### 🌐 `lib/server/server_manager.dart`
- **Purpose**: Unified server management
- **Responsibilities**:
  - Coordinate HTTP and WebSocket servers
  - Handle routing between HTTP and WebSocket requests
  - Provide unified API for server operations
- **Dependencies**: `http_server.dart`, `ws_server.dart`

### 📡 `lib/server/http_server.dart`
- **Purpose**: HTTP server for static file serving
- **Responsibilities**:
  - Serve web client files (HTML, CSS, JS)
  - Handle MIME type detection
  - Provide security (directory traversal protection)
- **Dependencies**: `shelf`, `path`

### 🔌 `lib/server/ws_server.dart`
- **Purpose**: WebSocket server for real-time communication
- **Responsibilities**:
  - Handle WebSocket connections
  - Process incoming messages
  - Manage connection lifecycle
  - Provide message logging and callbacks
- **Dependencies**: `shelf_web_socket`, `message_protocol.dart`

### 🌍 `lib/server/ip_utils.dart`
- **Purpose**: Network utilities
- **Responsibilities**:
  - Detect local IP addresses
  - List network interfaces
  - Validate IP addresses
  - Check network connectivity
- **Dependencies**: `dart:io`

### 📨 `lib/server/message_protocol.dart`
- **Purpose**: Message format definitions
- **Responsibilities**:
  - Define JSON message structures
  - Create standardized messages
  - Validate message formats
  - Provide message descriptions
- **Dependencies**: None (pure Dart)

---

## 🔄 Data Flow

### 1. **Server Startup**
```
main.dart → HomeScreen → ServerManager → HttpServer + WebSocketServer
```

### 2. **Client Connection**
```
Android Browser → HTTP Server → WebSocket Upgrade → WebSocket Server
```

### 3. **Message Processing**
```
Touch Event → WebSocket → MessageProtocol → ServerManager → UI Logs
```

### 4. **File Serving**
```
HTTP Request → ServerManager → HttpServer → Static File Response
```

---

## 🎯 Key Design Principles

### ✅ **Separation of Concerns**
- **Server Logic**: Isolated in `server/` directory
- **UI Logic**: Isolated in `ui/` directory
- **Client Code**: Isolated in `web_client/` directory

### ✅ **Modularity**
- Each component has a single responsibility
- Components can be tested independently
- Easy to extend and modify

### ✅ **Scalability**
- Server components can be easily expanded
- New message types can be added to protocol
- UI can be enhanced without affecting server logic

### ✅ **Maintainability**
- Clear file organization
- Consistent naming conventions
- Comprehensive error handling

---

## 🚀 Extension Points

### **Phase 2 - Mouse Control**
- Add mouse control logic to `ws_server.dart`
- Extend `message_protocol.dart` with new message types
- Add Windows API integration

### **Phase 3 - Keyboard Support**
- Extend message protocol for keyboard events
- Add keyboard input handling in web client
- Implement Windows keyboard APIs

### **Phase 4 - Advanced Features**
- Add authentication system
- Implement file transfer capabilities
- Add clipboard synchronization

---

## 🔧 Development Guidelines

### **Adding New Message Types**
1. Define message structure in `message_protocol.dart`
2. Add validation logic
3. Update `ws_server.dart` to handle new messages
4. Update web client to send new messages

### **Adding New UI Components**
1. Create new widget in `ui/` directory
2. Import and use in `home_screen.dart`
3. Follow Material Design principles
4. Ensure responsive design

### **Adding New Server Features**
1. Extend appropriate server component
2. Update `server_manager.dart` if needed
3. Add proper error handling
4. Update UI to reflect new features

---

## 🧪 Testing Strategy

### **Unit Testing**
- Test individual components in isolation
- Mock dependencies where appropriate
- Focus on business logic

### **Integration Testing**
- Test component interactions
- Verify data flow between components
- Test error handling paths

### **End-to-End Testing**
- Test complete user workflows
- Verify cross-platform compatibility
- Test network scenarios

---

## 📚 Dependencies

### **Core Dependencies**
- `shelf`: HTTP server framework
- `shelf_web_socket`: WebSocket support
- `path`: File path utilities
- `web_socket_channel`: WebSocket client/server

### **Flutter Dependencies**
- `flutter`: Core Flutter framework
- `cupertino_icons`: iOS-style icons

### **Development Dependencies**
- `flutter_test`: Testing framework
- `flutter_lints`: Code quality

---

## 🔍 Troubleshooting

### **Common Issues**
1. **Port already in use**: Check if another instance is running
2. **WebSocket connection fails**: Verify firewall settings
3. **Static files not served**: Check file paths and permissions
4. **IP detection fails**: Verify network interface configuration

### **Debug Tips**
- Check Flutter console for server logs
- Use browser developer tools for client debugging
- Verify network connectivity between devices
- Check Windows Firewall settings

---

## 📖 Further Reading

- [Shelf Documentation](https://pub.dev/packages/shelf)
- [WebSocket RFC](https://tools.ietf.org/html/rfc6455)
- [Flutter Desktop Development](https://docs.flutter.dev/desktop)
- [Material Design Guidelines](https://material.io/design)
