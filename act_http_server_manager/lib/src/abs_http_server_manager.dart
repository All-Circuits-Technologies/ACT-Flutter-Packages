// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/src/models/http_request_log.dart';
import 'package:act_http_server_manager/src/models/http_server_config.dart';
import 'package:act_http_server_manager/src/services/abs_api_service.dart';
import 'package:act_http_server_manager/src/services/handlers/abs_server_handler.dart';
import 'package:act_http_server_manager/src/services/handlers/request_id_server_handler.dart';
import 'package:act_http_server_manager/src/utilities/server_handler_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// This is the builder of the [AbsHttpServerManager]
abstract class AbsHttpServerBuilder<M extends AbsHttpServerManager> extends AbsManagerBuilder<M> {
  /// Class constructor
  const AbsHttpServerBuilder(super.factory);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
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

  /// This is the config linked to the HTTP server.
  late final HttpServerConfig _serverConfig;

  /// Instance of the http server
  late final HttpServer _httpServer;

  /// Instance of the http logging manager
  late final HttpLoggingManager _httpLoggingManager;

  /// Getter of [_httpLoggingManager]
  HttpLoggingManager get httpLoggingManager => _httpLoggingManager;

  /// Getter of [_apiServices]
  List<AbsApiService> get apiServices => _apiServices;

  /// Class constructor
  AbsHttpServerManager() : _apiServices = [], _globalHandlers = [];

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _httpLoggingManager = await getLoggingManager();

    _serverConfig = await getServerConfig(httpLoggingManager: _httpLoggingManager);

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

    _httpServer = await _initServer(config: _serverConfig);
  }

  /// {@template act_http_server_manager.HttpServerManager.getLoggingManager}
  /// Get the logging manager linked to this http server manager
  /// {@endtemplate}
  @protected
  Future<HttpLoggingManager> getLoggingManager() async => globalGetIt().get<HttpLoggingManager>();

  /// {@template act_http_server_manager.HttpServerManager.getServerConfig}
  /// Get the config linked to the HTTP server.
  /// {@endtemplate}
  @protected
  Future<HttpServerConfig> getServerConfig({required HttpLoggingManager httpLoggingManager});

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
        logLevel: Level.trace,
        message: "The route isn't found",
      ),
    );
    return Router.routeNotFound;
  }

  /// Initialize the server
  Future<HttpServer> _initServer({required HttpServerConfig config}) async {
    final appRouter = Router(notFoundHandler: manageNotFoundRoute);

    await Future.wait(_apiServices.map((service) => service.initRoutes(appRouter)));

    final server = await io.serve(
      (request) => ServerHandlersUtility.manageServerHandlers(
        innerHandler: appRouter.call,
        request: request,
        routeHandlers: _globalHandlers,
      ),
      config.hostname,
      config.port,
    );
    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: "server-start: ${config.serverName}",
        route: '/',
        method: '/',
        logLevel: Level.info,
        message: 'Server: ${config.serverName} started on ${server.address.host}:${server.port}',
      ),
    );

    return server;
  }

  /// Close the given [server]
  Future<void> _closeServer(HttpServer server) async {
    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: "server-close: ${_serverConfig.serverName}",
        route: '/',
        method: '/',
        logLevel: Level.info,
        message: 'Server closed on ${server.address.host}:${server.port}',
      ),
    );
    await server.close(force: true);
  }

  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait(_globalHandlers.map((service) => service.disposeLifeCycle()));
    await Future.wait(_apiServices.map((service) => service.disposeLifeCycle()));
    await _closeServer(_httpServer);
    return super.disposeLifeCycle();
  }
}
