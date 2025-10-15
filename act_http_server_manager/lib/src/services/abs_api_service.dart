// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:convert';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/src/models/http_request_log.dart';
import 'package:act_http_server_manager/src/models/http_route_listening_id.dart';
import 'package:act_http_server_manager/src/models/http_server_config.dart';
import 'package:act_http_server_manager/src/services/handlers/abs_server_handler.dart';
import 'package:act_http_server_manager/src/utilities/server_handler_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// This is the abstract class for all the api services
abstract class AbsApiService extends AbsWithLifeCycle {
  /// This is the key used in the request context to store the request id
  static const requestIdContext = "requestId";

  /// This is the server config
  final HttpServerConfig _config;

  /// Instance of the http logging manager
  final HttpLoggingManager _httpLoggingManager;

  /// This is the base path to use for all the routes in the service
  final String serviceBasePath;

  /// This is the list of all the registered routes in the service
  final List<HttpRouteListeningId> registeredRoutes;

  /// This is the HttpLoggingManager getter
  @protected
  HttpLoggingManager get httpLoggingManager => _httpLoggingManager;

  /// This is the [HttpServerConfig] getter
  @protected
  HttpServerConfig get config => _config;

  /// Class constructor
  ///
  /// The [serviceRelativePath] is a path used for all the routes in the service and which is
  /// between the relative request route and the server base path.
  AbsApiService({
    required HttpLoggingManager httpLoggingManager,
    required HttpServerConfig config,
    String? serviceRelativePath,
  }) : _httpLoggingManager = httpLoggingManager,
       _config = config,
       serviceBasePath = _formatServiceBasePath(
         config: config,
         serviceRelativePath: serviceRelativePath,
       ),
       registeredRoutes = [];

  /// {@template act_http_server_manager.abs_api_service.initRoutes}
  /// This method is used to define the request methods to add to the router
  /// {@endtemplate}
  Future<void> initRoutes(Router app);

  /// Called to register a GET request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onGet({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.get,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register a PUT request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onPut({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.put,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register a POST request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onPost({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.post,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register a DELETE request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onDelete({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.delete,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register a HEAD request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onHead({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.head,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register an OPTIONS request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onOptions({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.options,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register a CONNECT request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onConnect({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.connect,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register a PATCH request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onPatch({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.patch,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register a TRACE request to the [app]
  ///
  /// {@macro act_http_server_manager.AbsApiService.onRequest}
  @protected
  void onTrace({
    required Router app,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) => onRequest(
    app: app,
    method: HttpMethods.trace,
    relativeRoute: relativeRoute,
    innerHandler: innerHandler,
    routeHandlers: routeHandlers,
  );

  /// Called to register a request with [method] to the [app].
  ///
  /// {@template act_http_server_manager.AbsApiService.onRequest}
  /// Register an [innerHandler] to the [relativeRoute]. The [relativeRoute] shouldn't begin with a
  /// path separator (except if it's needed).
  ///
  /// The route handlers are called sequentially to add information to the request before calling
  /// [innerHandler]. Or to add information to the response.
  /// {@endtemplate}
  @protected
  void onRequest({
    required Router app,
    required HttpMethods method,
    required String relativeRoute,
    required Handler innerHandler,
    List<AbsServerHandler> routeHandlers = const [],
  }) {
    final tmpRoute = _formatServiceRoute(relativeRoute);
    app.add(
      method.stringValue,
      tmpRoute,
      (Request request) => ServerHandlersUtility.manageServerHandlers(
        innerHandler: innerHandler,
        request: request,
        routeHandlers: routeHandlers,
      ),
    );
    registeredRoutes.add(
      HttpRouteListeningId.fromRouteListening(method: method, relativeRoute: tmpRoute),
    );
  }

  /// Helper method to get the json object body from a request
  @protected
  Future<Map<String, dynamic>?> getJsonObjectBody({
    required String requestId,
    required Request request,
  }) async => _getJsonBody<Map<String, dynamic>>(requestId: requestId, request: request);

  /// Helper method to get and parse the json object body from a request
  @protected
  Future<T?> getParsedJsonObjectBody<T>({
    required String requestId,
    required Request request,
    required T? Function(Map<String, dynamic> json) parser,
  }) async {
    final jsonBody = await getJsonObjectBody(requestId: requestId, request: request);
    if (jsonBody == null) {
      // An error occurred before
      return null;
    }

    final parsedBody = parser(jsonBody);
    if (parsedBody == null) {
      _httpLoggingManager.addLog(
        HttpRequestLog.requestNow(
          requestId: requestId,
          request: request,
          logLevel: Level.warning,
          message: "The json contained in the body couldn't be parsed",
        ),
      );
      return null;
    }

    return parsedBody;
  }

  /// Helper method to get the json array body from a request
  @protected
  Future<List<dynamic>?> getJsonArrayBody({
    required String requestId,
    required Request request,
  }) async => _getJsonBody<List<dynamic>>(requestId: requestId, request: request);

  /// Helper method to get and parse the json object body from a request
  @protected
  Future<List<T>?> getParsedJsonArrayBody<T>({
    required String requestId,
    required Request request,
    required T? Function(Map<String, dynamic> json) parser,
  }) async {
    final jsonBody = await getJsonArrayBody(requestId: requestId, request: request);
    if (jsonBody == null) {
      // An error occurred before
      return null;
    }

    final elementsParsedBody = <T>[];
    for (final element in jsonBody) {
      if (element is! Map<String, dynamic>) {
        _httpLoggingManager.addLog(
          HttpRequestLog.requestNow(
            requestId: requestId,
            request: request,
            logLevel: Level.warning,
            message:
                "The json contained in the body hasn't the expected type: Map<String, dynamic>",
          ),
        );
        return null;
      }

      final parsedElem = parser(element);
      if (parsedElem == null) {
        _httpLoggingManager.addLog(
          HttpRequestLog.requestNow(
            requestId: requestId,
            request: request,
            logLevel: Level.warning,
            message: "One element of the json contained in the body couldn't be parsed",
          ),
        );
        return null;
      }

      elementsParsedBody.add(parsedElem);
    }

    return elementsParsedBody;
  }

  /// Manage the middlewares for the given handler
  @protected
  Handler manageMiddlewares(Handler innerHandler, {List<Middleware> extraMiddlewares = const []}) {
    var pipeline = const Pipeline();

    for (final extra in extraMiddlewares) {
      pipeline = pipeline.addMiddleware(extra);
    }

    return pipeline.addHandler(innerHandler);
  }

  @protected
  /// Helper method to get the json body from a request
  Future<T?> _getJsonBody<T>({required String requestId, required Request request}) async {
    dynamic jsonBody;
    try {
      final jsonBodyStr = await request.readAsString();
      jsonBody = jsonDecode(jsonBodyStr);
    } catch (error) {
      _httpLoggingManager.addLog(
        HttpRequestLog.requestNow(
          requestId: requestId,
          request: request,
          logLevel: Level.error,
          message: "A problem occurred when tried to parse the JSON body received: $error",
        ),
      );
    }

    if (jsonBody == null) {
      // An error occurred before
      return null;
    }

    if (jsonBody is! T) {
      _httpLoggingManager.addLog(
        HttpRequestLog.requestNow(
          requestId: requestId,
          request: request,
          logLevel: Level.warning,
          message: "The json contained in the body hasn't the expected type: $T",
        ),
      );
      return null;
    }

    return jsonBody;
  }

  /// Format the route for the server
  String _formatServiceRoute(String route) => '$serviceBasePath$route';

  /// Format the base path for all the requests in the service from the server base path and the
  /// [serviceRelativePath].
  ///
  /// The returned path always begins and ends with a path separator.
  @protected
  static String _formatServiceBasePath({
    required HttpServerConfig config,
    required String? serviceRelativePath,
  }) {
    var serviceBasePath = config.basePath ?? UriUtility.pathSeparator;

    if (!serviceBasePath.startsWith(UriUtility.pathSeparator)) {
      // The path doesn't begin with the path separator, we need one at start, so we add it
      serviceBasePath = "${UriUtility.pathSeparator}$serviceBasePath";
    }

    if (serviceRelativePath != null) {
      final basePathEndsWithSep = serviceBasePath.endsWith(UriUtility.pathSeparator);
      final relativePathStartWithSep = serviceRelativePath.startsWith(UriUtility.pathSeparator);

      if (!basePathEndsWithSep && !relativePathStartWithSep) {
        serviceBasePath = "$serviceBasePath${UriUtility.pathSeparator}$serviceRelativePath";
      } else if (basePathEndsWithSep && relativePathStartWithSep) {
        serviceBasePath =
            "${serviceBasePath.substring(0, serviceBasePath.length - 1)}$serviceRelativePath";
      } else {
        serviceBasePath = "$serviceBasePath$serviceRelativePath";
      }
    }

    if (!serviceBasePath.endsWith(UriUtility.pathSeparator)) {
      serviceBasePath = "$serviceBasePath${UriUtility.pathSeparator}";
    }

    return serviceBasePath;
  }
}
