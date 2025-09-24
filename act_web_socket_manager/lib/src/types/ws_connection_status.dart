// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This describes the web socket connection status
enum WsConnectionStatus {
  /// When the socket is disconnected from the server
  disconnected,

  /// When the socket is connecting to the server
  connecting,

  /// When the socket is connected to the server
  connected,
}
