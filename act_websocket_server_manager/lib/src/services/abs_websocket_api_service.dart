// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_websocket_server_manager/src/models/websocket_server_config.dart';
import 'package:act_websocket_server_manager/src/services/abs_websocket_channel_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// This is the abstract class for WebSocket API services
abstract class AbsWebsocketApiService extends AbsApiService {
  /// The WebSocket server config
  late final WebsocketServerConfig wsConfig;

  /// The map of all the WebSocket channel services
  final Map<String, AbsWebsocketChannelService> _channelServices;

  /// Class constructor
  ///
  /// The [serviceRelativePath] is the path of the WebSocket servers
  AbsWebsocketApiService({
    required super.httpLoggingManager,
    required super.config,
    super.serviceRelativePath,
  }) : _channelServices = {};

  /// {@template act_websocket_server_manager.AbsWebsocketService.getWsConfig}
  /// Get the WebSocket server config
  /// {@endtemplate}
  @protected
  Future<WebsocketServerConfig> getWsConfig() async => const WebsocketServerConfig();

  /// {@template act_websocket_server_manager.AbsWebsocketService.createChannelService}
  /// Create a new WebSocket channel service.
  ///
  /// The method [onClose] has to be called when the WebSocket is closed, to free the resources.
  /// {@endtemplate}
  @protected
  Future<AbsWebsocketChannelService> createChannelService({
    required HttpLoggingManager httpLoggingManager,
    required WebSocketChannel channel,
    required String? subProtocol,
    required void Function(String clientUuid) onClose,
  });

  /// {@macro act_http_server_manager.abs_api_service.initRoutes}
  @override
  Future<void> initRoutes(Router app) async {
    wsConfig = await getWsConfig();

    app.get(
      _wsRoute,
      webSocketHandler(
        _onNewWebSocketConnection,
        protocols: wsConfig.protocols,
        allowedOrigins: wsConfig.allowedOrigins,
        pingInterval: wsConfig.pingInterval,
      ),
    );
  }

  /// Get the WebSocket route from [serviceBasePath]
  String get _wsRoute {
    final tmpRoute = serviceBasePath;
    final length = tmpRoute.length;
    if (length <= 1) {
      return tmpRoute;
    }

    return tmpRoute.substring(0, length - 1);
  }

  /// Called when a new WebSocket connection is established
  ///
  /// This creates a new WebSocket service for each client
  Future<void> _onNewWebSocketConnection(WebSocketChannel webSocket, String? subProtocol) async {
    final webSocketService = await createChannelService(
      httpLoggingManager: httpLoggingManager,
      channel: webSocket,
      subProtocol: subProtocol,
      onClose: _onWebSocketClosed,
    );
    _channelServices[webSocketService.clientUuid] = webSocketService;
    await webSocketService.initLifeCycle();
  }

  /// Called when a WebSocket connection is closed to free the resources
  void _onWebSocketClosed(String clientUuid) {
    _channelServices.remove(clientUuid);
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait(_channelServices.values.map((service) => service.disposeLifeCycle()));

    return super.disposeLifeCycle();
  }
}
