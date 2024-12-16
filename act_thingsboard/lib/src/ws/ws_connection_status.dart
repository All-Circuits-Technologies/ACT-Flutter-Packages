// Copyright (c) 2020. BMS Circuits

/// [WebSocketManager] status enum
enum WsConnectionStatus {
  disconnected,
  connected,
}

/// Extension of the web socket connection status
extension WsConnectionStatusExtension on WsConnectionStatus {
  String get str => this.toString().split('.').last;
}
