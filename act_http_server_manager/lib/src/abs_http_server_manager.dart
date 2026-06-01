// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/src/models/http_request_log.dart';
import 'package:act_http_server_manager/src/models/http_server_config.dart';
import 'package:act_http_server_manager/src/services/abs_api_service.dart';
import 'package:act_http_server_manager/src/services/handlers/abs_server_handler.dart';
import 'package:act_http_server_manager/src/services/handlers/request_id_server_handler.dart';
import 'package:act_http_server_manager/src/utilities/server_handler_utility.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// This is the builder of the [AbsHttpServerManager]
abstract class AbsHttpServerBuilder<M extends AbsHttpServerManager> extends AbsLifeCycleFactory<M> {
  /// Class constructor
  const AbsHttpServerBuilder(super.factory);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager, HttpLoggingManager];
}

/// This class is used to manage the http server
/// It will create a server and listen to the requests
abstract class AbsHttpServerManager extends AbsWithLifeCycle {
  /// This is the list of API services managed by the manager
  final List<AbsApiService> _apiServices;

  /// This is the list of the global handlers to use on the routes of the server
  final List<AbsServerHandler> _globalHandlers;

  /// Whether the server should be started on init or not
  final bool startServerOnInit;

  /// Instance of the http logging manager
  late final HttpLoggingManager _httpLoggingManager;

  /// Instance of the http server
  HttpServer? _httpServer;

  /// This is the config linked to the HTTP server.
  late HttpServerConfig _serverConfig;

  /// Getter of [_httpLoggingManager]
  HttpLoggingManager get httpLoggingManager => _httpLoggingManager;

  /// Getter of [_apiServices]
  List<AbsApiService> get apiServices => _apiServices;

  /// Class constructor
  AbsHttpServerManager({this.startServerOnInit = true}) : _apiServices = [], _globalHandlers = [];

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _httpLoggingManager = await getLoggingManager();

    _serverConfig = await getInitServerConfig(httpLoggingManager: _httpLoggingManager);

    final tmpServices = await getApiServices(
      config: _serverConfig,
      httpLoggingManager: _httpLoggingManager,
    );
    _apiServices.addAll(tmpServices);
    await Future.wait(_apiServices.map((service) => service.initLifeCycle()));

    final globalHandlers = await getGlobalHandlers(
      config: _serverConfig,
      httpLoggingManager: _httpLoggingManager,
      apiServices: tmpServices,
    );
    _globalHandlers.addAll(globalHandlers);
    await Future.wait(_globalHandlers.map((handler) => handler.initLifeCycle()));

    if (startServerOnInit) {
      await _initServer(config: null);
    }
  }

  /// Restart the server with the current config or with a new one if it's provided
  Future<void> restartServer({HttpServerConfig? config}) => _initServer(config: config);

  /// {@template act_http_server_manager.HttpServerManager.getLoggingManager}
  /// Get the logging manager linked to this http server manager
  /// {@endtemplate}
  @protected
  Future<HttpLoggingManager> getLoggingManager() async => globalGetIt().get<HttpLoggingManager>();

  /// {@template act_http_server_manager.HttpServerManager.getServerConfig}
  /// Get the config linked to the HTTP server.
  /// {@endtemplate}
  @protected
  Future<HttpServerConfig> getInitServerConfig({required HttpLoggingManager httpLoggingManager});

  /// {@template act_http_server_manager.HttpServerManager.getApiServices}
  /// Get the services to use in the server.
  /// {@endtemplate}
  @protected
  Future<List<AbsApiService>> getApiServices({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
  });

  /// {@template act_http_server_manager.HttpServerManager.getGlobalHandlers}
  /// Get the global handlers to use in the server.
  ///
  /// Be careful, the [apiServices] are initialized but the initRoutes method hasn't been called
  /// yet.
  /// {@endtemplate}
  ///
  /// By default, add the request id handler.
  @protected
  Future<List<AbsServerHandler>> getGlobalHandlers({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
    required List<AbsApiService> apiServices,
  }) async => [RequestIdServerHandler(httpLoggingManager: httpLoggingManager)];

  /// {@template act_http_server_manager.HttpServerManager.manageNotFoundRoute}
  /// This is the handler to use when the server route isn't found
  /// {@endtemplate}
  @protected
  Future<Response> manageNotFoundRoute(Request request) async {
    _httpLoggingManager.addLog(
      HttpRequestLog.requestNow(
        requestId: "not-found",
        request: request,
        logLevel: LogsLevel.trace,
        message: "The route isn't found",
      ),
    );
    return Router.routeNotFound;
  }

  /// Initialize the server
  ///
  /// Set the [_httpServer] and the [_serverConfig] with the created server and the used config
  Future<HttpServer> _initServer({required HttpServerConfig? config}) async {
    await _setConfig(newConfig: _serverConfig);

    if (_httpServer != null) {
      // The server is already initialized, we need to close it before re-initializing it
      await _closeServer();
    }

    final appRouter = Router(notFoundHandler: manageNotFoundRoute);

    await Future.wait(_apiServices.map((service) => service.initRoutes(appRouter)));

    HttpServer? server;

    for (var idx = _serverConfig.portsRange.min; idx <= _serverConfig.portsRange.max; idx++) {
      try {
        server = await io.serve(
          (request) => ServerHandlersUtility.manageServerHandlers(
            innerHandler: appRouter.call,
            request: request,
            routeHandlers: _globalHandlers,
          ),
          _serverConfig.hostname,
          idx,
        );

        // The server is successfully initialized, we can stop trying to initialize it on other
        // ports
        break;
      } on SocketException catch (e) {
        if (idx == _serverConfig.portsRange.max) {
          appLogger().e("Failed to start the HTTP server on ${_serverConfig.hostname}:$idx", e);
          rethrow;
        }
      }
    }

    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: "server-start: ${_serverConfig.serverName}",
        route: '/',
        method: '/',
        logLevel: LogsLevel.info,
        message:
            'Server: ${_serverConfig.serverName} started on ${server!.address.host}:${server.port}',
      ),
    );

    _httpServer = server;

    return server;
  }

  /// Close the [_httpServer] if it's not null
  Future<void> _closeServer() async {
    if (_httpServer == null) {
      // Nothing to do
      return;
    }

    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: "server-close: ${_serverConfig.serverName}",
        route: '/',
        method: '/',
        logLevel: LogsLevel.info,
        message: 'Server closed on ${_httpServer!.address.host}:${_httpServer!.port}',
      ),
    );
    await _httpServer!.close(force: true);

    _httpServer = null;
  }

  /// This method is used to update the config of the server and all the services with the new one.
  @protected
  Future<void> _setConfig({required HttpServerConfig newConfig}) async {
    if (newConfig == _serverConfig) {
      return;
    }

    _serverConfig = newConfig;
    await Future.wait(_apiServices.map((service) => service.updateConfig(newConfig: newConfig)));
  }

  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait(_globalHandlers.map((service) => service.disposeLifeCycle()));
    await Future.wait(_apiServices.map((service) => service.disposeLifeCycle()));
    await _closeServer();
    return super.disposeLifeCycle();
  }
}
