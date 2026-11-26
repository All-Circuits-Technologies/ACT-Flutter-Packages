// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// Extends the [AbstractConfigManager] to add config variables which will be used by the
/// abstract websocket manager
mixin MixinWebsocketServerConfig on AbstractConfigManager {
  /// This is the name of the WebSocket server used to identify it
  final wsServerName = const NotNullableConfigVar<String>(
    "webSocket.server.name",
    defaultValue: "WebSocket server",
  );

  /// This is the hostname to use when we create the WebSocket server
  final wsServerHostname = const NotNullableConfigVar<String>(
    "webSocket.server.hostname",
    defaultValue: "0.0.0.0",
  );

  /// This is the port to use when we create the WebSocket server
  final wsServerPort = const NotNullableConfigVar<int>("webSocket.server.port", defaultValue: 80);

  /// This is the base path to use for all the routes in the WebSocket server
  final wsServerBasePath = const ConfigVar<String>("webSocket.server.basePath");
}
