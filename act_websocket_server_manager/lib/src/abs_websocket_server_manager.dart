// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_websocket_server_manager/src/services/abs_websocket_api_service.dart';
import 'package:flutter/foundation.dart';

/// This is the builder of the [AbsWebsocketServerManager]
abstract class AbsWebsocketServerBuilder<M extends AbsWebsocketServerManager>
    extends AbsHttpServerBuilder<M> {
  /// Class constructor
  const AbsWebsocketServerBuilder(super.factory);
}

/// This is the WebSocket server manager of the Backend stub server
abstract class AbsWebsocketServerManager extends AbsHttpServerManager {
  /// Class constructor
  AbsWebsocketServerManager() : super();

  /// {@macro act_http_server_manager.HttpServerManager.getApiServices}
  @override
  Future<List<AbsApiService>> getApiServices({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
  }) async => [await getWebsocketService(config: config, httpLoggingManager: httpLoggingManager)];

  /// {@template act_websocket_server_manager.AbsWebsocketServerManager.getWebsocketService}
  /// Get the WebSocket service
  ///
  /// Use this method instead of [getApiServices].
  /// {@endtemplate}
  @protected
  Future<AbsWebsocketApiService> getWebsocketService({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
  });

  /// {@macro act_http_server_manager.HttpServerManager.getGlobalHandlers}
  ///
  /// By default, there is no handler.
  @override
  Future<List<AbsServerHandler>> getGlobalHandlers({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
    required List<AbsApiService> apiServices,
  }) async => [];
}
