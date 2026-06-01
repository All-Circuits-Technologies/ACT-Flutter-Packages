// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_websocket_server_manager/src/mixins/mixin_websocket_server_config.dart';
import 'package:flutter/foundation.dart';

/// This mixin can be used to get the WebSocket server config from a config manager
mixin MixinFromConfigWsServerManager on AbsHttpServerManager {
  /// {@template act_websocket_server_manager.MixinFromConfigWsServerManager.configGetter}
  /// This is the getter of the config manager
  /// {@endtemplate}
  @protected
  MixinWebsocketServerConfig Function() get configGetter;

  /// {@macro act_http_server_manager.HttpServerManager.getServerConfig}
  @override
  Future<HttpServerConfig> getInitServerConfig({
    required HttpLoggingManager httpLoggingManager,
  }) async {
    final configManager = configGetter();
    final wsServerPort = configManager.wsServerPort.load();

    NumBoundaries<int> portsRange;
    if (wsServerPort == null) {
      portsRange = configManager.httpServerPortsRange.load();
    } else {
      portsRange = NumBoundaries<int>(min: wsServerPort, max: wsServerPort);
    }

    return HttpServerConfig(
      serverName: configManager.wsServerName.load(),
      hostname: configManager.wsServerHostname.load(),
      portsRange: portsRange,
      basePath: configManager.wsServerBasePath.load(),
    );
  }
}
