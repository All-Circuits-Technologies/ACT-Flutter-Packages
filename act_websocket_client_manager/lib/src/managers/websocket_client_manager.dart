// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_websocket_client_manager/src/managers/abs_websocket_client_manager.dart';
import 'package:act_websocket_client_manager/src/mixins/mixin_websocket_client_config.dart';
import 'package:act_websocket_client_manager/src/models/ws_client_manager_config.dart';

/// Builder for creating the WebSocketManager
class SimpleWebsocketClientBuilder<C extends MixinWebsocketClientConfig>
    extends AbsWebsocketClientBuilder<WebsocketClientManager> {
  /// Class constructor
  SimpleWebsocketClientBuilder()
    : super(factory: () => WebsocketClientManager(configGetter: globalGetIt().get<C>));
}

/// This is the WebSocket manager
///
/// If you want to create multiple managers, use [AbsWebsocketClientBuilder].
class WebsocketClientManager extends AbsWebsocketClientManager {
  /// This is the default value of the start WebSocket at manager init
  static const _startWsAtManagerInitDefaultValue = true;

  /// This is the default logger category
  static const defaultLoggerCategory = "ws";

  /// This is the getter of the config manager
  final MixinWebsocketClientConfig Function() _configGetter;

  /// Class constructor
  WebsocketClientManager({
    required MixinWebsocketClientConfig Function() configGetter,
    super.loggerCategory = defaultLoggerCategory,
  }) : _configGetter = configGetter;

  /// {@macro act_websocket_client_manager.WebsocketClientManager.getConfig}
  @override
  Future<WsClientManagerConfig> getConfig({required LogsHelper logsHelper}) async =>
      WsClientManagerConfig(
        uri: _configGetter().websocketClientUrl.load(),
        autoReconnectEnabled: _configGetter().websocketClientAutoRecoEnabled.load(),
        autoReconnectInitDuration: _configGetter().websocketClientAutoRecoInitDurationInMs.load(),
        autoReconnectMaxDuration: _configGetter().websocketClientAutoRecoMaxDurationInMs.load(),
        startWsAtManagerInit: _startWsAtManagerInitDefaultValue,
        msgParsers: const [],
        protocols: const [],
        logReceivedMsg: _configGetter().websocketClientLogReceivedMsg.load(),
      );
}
