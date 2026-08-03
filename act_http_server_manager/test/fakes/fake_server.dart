// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart' show Handler, Middleware;

/// The logging manager of a server, which keeps the logs the test reads.
class FakeHttpLogging extends HttpLoggingManager {
  /// The logs the server wrote, in the order it wrote them.
  final List<HttpLog> logs = [];

  /// The messages of the logs the server wrote.
  List<String> get messages => logs.map((log) => log.message).toList();

  @override
  void addLog(HttpLog log) {
    logs.add(log);
    super.addLog(log);
  }
}

/// A handler of the server which does what the test decided.
///
/// It records what it was called with, which is what a test reads to know the order the handlers
/// of a route were called in.
class FakeServerHandler extends AbsServerHandler {
  /// The name the handler records its calls under.
  final String name;

  /// The response the handler answers with instead of letting the route answer, if it has one.
  final Response? forcedResponse;

  /// The header the handler adds to the request before the route reads it, if it adds one.
  final MapEntry<String, String>? addedHeader;

  /// The header the handler adds to the response, if it adds one.
  final MapEntry<String, String>? addedResponseHeader;

  /// The calls the handlers of a route received, in the order they received them.
  final List<String> calls;

  /// Class constructor
  const FakeServerHandler({
    required super.httpLoggingManager,
    required this.calls,
    this.name = "a handler",
    this.forcedResponse,
    this.addedHeader,
    this.addedResponseHeader,
  });

  /// {@macro act_http_server_manager.AbsServerHandler.beforeHandler}
  @override
  Future<({Response? forceResponse, Request? overrideRequest})> beforeHandler({
    required Request request,
  }) async {
    calls.add("$name.before");

    return (
      forceResponse: forcedResponse,
      overrideRequest: addedHeader == null
          ? null
          : request.change(headers: {addedHeader!.key: addedHeader!.value}),
    );
  }

  @override
  Future<void> disposeLifeCycle() async {
    calls.add("$name.dispose");

    return super.disposeLifeCycle();
  }

  /// {@macro act_http_server_manager.AbsServerHandler.afterHandler}
  @override
  Future<Response> afterHandler({required Request request, required Response response}) async {
    calls.add("$name.after");

    return addedResponseHeader == null
        ? response
        : response.change(headers: {addedResponseHeader!.key: addedResponseHeader!.value});
  }
}

/// A handler of the server which does nothing more than the abstract class does.
class BareServerHandler extends AbsServerHandler {
  /// Class constructor
  const BareServerHandler({required super.httpLoggingManager});
}

/// A service of a server, which answers on a couple of routes.
class FakeApiService extends AbsApiService {
  /// The handlers to call on the routes of the service.
  final List<AbsServerHandler> routeHandlers;

  /// The bodies the routes of the service read, in the order they read them.
  final List<Object?> readBodies = [];

  /// The number of times the service was initialized.
  int initCount = 0;

  /// The number of times the service was disposed.
  int disposeCount = 0;

  /// Class constructor
  FakeApiService({
    required super.httpLoggingManager,
    required super.config,
    super.serviceRelativePath,
    this.routeHandlers = const [],
  });

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    initCount++;
  }

  @override
  Future<void> disposeLifeCycle() async {
    disposeCount++;

    return super.disposeLifeCycle();
  }

  /// {@macro act_http_server_manager.abs_api_service.initRoutes}
  @override
  Future<void> initRoutes(Router app) async {
    onGet(
      app: app,
      relativeRoute: "hello",
      innerHandler: (request) => Response.ok("hello"),
      routeHandlers: routeHandlers,
    );
    onGet(
      app: app,
      relativeRoute: "item/<itemId>",
      innerHandler: (request) => Response.ok(request.params["itemId"]),
    );
    onPost(app: app, relativeRoute: "object", innerHandler: _readObject);
    onPost(app: app, relativeRoute: "array", innerHandler: _readArray);
    onPut(app: app, relativeRoute: "put", innerHandler: (request) => Response.ok(null));
    onDelete(app: app, relativeRoute: "delete", innerHandler: (request) => Response.ok(null));
    onHead(app: app, relativeRoute: "head", innerHandler: (request) => Response.ok(null));
    onOptions(app: app, relativeRoute: "options", innerHandler: (request) => Response.ok(null));
    onConnect(app: app, relativeRoute: "connect", innerHandler: (request) => Response.ok(null));
    onPatch(app: app, relativeRoute: "patch", innerHandler: (request) => Response.ok(null));
    onTrace(app: app, relativeRoute: "trace", innerHandler: (request) => Response.ok(null));
  }

  /// Reads the body of the request as one json object.
  Future<Response> _readObject(Request request) async {
    final body = await getJsonObjectBody(requestId: "a request", request: request);
    readBodies.add(body);

    return body == null ? Response.badRequest() : Response.ok(null);
  }

  /// Reads the body of the request as a list of json objects.
  Future<Response> _readArray(Request request) async {
    final body = await getJsonArrayBody(requestId: "a request", request: request);
    readBodies.add(body);

    return body == null ? Response.badRequest() : Response.ok(null);
  }

  /// Reads the body of [request] as one json object.
  Future<Map<String, dynamic>?> readObjectBody(Request request) =>
      getJsonObjectBody(requestId: "a request", request: request);

  /// Reads the body of [request] as a list of json objects.
  Future<List<dynamic>?> readArrayBody(Request request) =>
      getJsonArrayBody(requestId: "a request", request: request);

  /// Reads the body of [request] as one json object and builds a value of it with [parser].
  Future<T?> readParsedObjectBody<T>(
    Request request,
    T? Function(Map<String, dynamic> json) parser,
  ) => getParsedJsonObjectBody<T>(requestId: "a request", request: request, parser: parser);

  /// Reads the body of [request] as a list of json objects and builds values of them with [parser].
  Future<List<T>?> readParsedArrayBody<T>(
    Request request,
    T? Function(Map<String, dynamic> json) parser,
  ) => getParsedJsonArrayBody<T>(requestId: "a request", request: request, parser: parser);

  /// Wraps [innerHandler] in [extraMiddlewares], the way a route of a service does.
  Handler wrapInMiddlewares(Handler innerHandler, List<Middleware> extraMiddlewares) =>
      manageMiddlewares(innerHandler, extraMiddlewares: extraMiddlewares);
}

/// The configuration of an application which runs a server.
class FakeServerConfig extends AbstractConfigManager with MixinHttpServerConfig {
  /// Class constructor
  FakeServerConfig() : super(logger: const SilentLogger());
}

/// The server manager of an application, which reads its configuration from the test.
class FakeHttpServerManager extends AbsHttpServerManager {
  /// The configuration of the server.
  final HttpServerConfig serverConfig;

  /// The logging manager of the server.
  final HttpLoggingManager logging;

  /// The services which answer on the routes of the server.
  final List<AbsApiService> services;

  /// The handlers the server calls on every route, if the test decided any.
  final List<AbsServerHandler>? globalHandlers;

  /// Whether the server has already been closed.
  ///
  /// A test which closes the server itself leaves nothing for the tear down to close.
  bool disposed = false;

  /// Class constructor
  FakeHttpServerManager({
    required this.serverConfig,
    required this.logging,
    required this.services,
    this.globalHandlers,
  });

  @override
  Future<void> disposeLifeCycle() async {
    if (disposed) {
      return;
    }

    disposed = true;

    return super.disposeLifeCycle();
  }

  /// {@macro act_http_server_manager.HttpServerManager.getLoggingManager}
  @override
  Future<HttpLoggingManager> getLoggingManager() async => logging;

  /// {@macro act_http_server_manager.HttpServerManager.getServerConfig}
  @override
  Future<HttpServerConfig> getServerConfig({
    required HttpLoggingManager httpLoggingManager,
  }) async => serverConfig;

  /// {@macro act_http_server_manager.HttpServerManager.getApiServices}
  @override
  Future<List<AbsApiService>> getApiServices({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
  }) async => services;

  /// {@macro act_http_server_manager.HttpServerManager.getGlobalHandlers}
  @override
  Future<List<AbsServerHandler>> getGlobalHandlers({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
    required List<AbsApiService> apiServices,
  }) async =>
      globalHandlers ??
      super.getGlobalHandlers(
        config: config,
        httpLoggingManager: httpLoggingManager,
        apiServices: apiServices,
      );
}

/// The builder of the server manager of an application under test.
class FakeHttpServerBuilder extends AbsHttpServerBuilder<FakeHttpServerManager> {
  /// Class constructor
  const FakeHttpServerBuilder(super.factory);
}

/// The server manager of an application which reads its configuration from its configuration
/// manager.
class FakeConfiguredServerManager extends AbsHttpServerManager
    with MixinFromConfigHttpServerManager {
  /// The configuration manager of the application.
  final FakeServerConfig configManager;

  /// Class constructor
  FakeConfiguredServerManager({required this.configManager});

  /// {@macro act_http_server_manager.MixinFromConfigHttpServerManager.configGetter}
  @override
  MixinHttpServerConfig Function() get configGetter =>
      () => configManager;

  /// The configuration of the server, as the mixin reads it from the configuration manager.
  Future<HttpServerConfig> readServerConfig(HttpLoggingManager logging) =>
      getServerConfig(httpLoggingManager: logging);

  /// {@macro act_http_server_manager.HttpServerManager.getApiServices}
  @override
  Future<List<AbsApiService>> getApiServices({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
  }) async => [];
}

/// A handler of the kind of JWT the tests of the server sign and verify.
class FakeJwtHandler extends AbstractJwtHandler {
  /// The key the handler signs and verifies with.
  final JWTKey key;

  /// The options the handler reads its claims from.
  final JwtOptions jwtOptions;

  /// Class constructor
  FakeJwtHandler({required super.logsHelper, required this.key, JwtOptions? options})
    : jwtOptions =
          options ??
          JwtOptions(
            algorithm: JWTAlgorithm.HS256,
            audience: Audience.one("an audience"),
            issuer: "an issuer",
            subject: "a subject",
            expirationTime: const Duration(hours: 1),
          ),
      super(name: "a handler");

  /// {@macro act_jwt_utilities.AbstractJwtHandler.initHandlerImpl}
  @override
  Future<bool> initHandlerImpl() async {
    await initKeys(publicKey: key, privateKey: key);

    return true;
  }

  /// {@macro act_jwt_utilities.AbstractJwtHandler.getJwtOptions}
  @override
  Future<JwtOptions> getJwtOptions() async => jwtOptions;

  /// {@macro act_jwt_utilities.AbstractJwtHandler.testSignAndVerify}
  @override
  Future<bool> testSignAndVerify() => testSignAndVerifyImpl(const {"aClaim": "a value"});

  /// Signs a token which carries [payload], the way the server signs the ones it hands out.
  Future<SignResult?> signToken(Map<String, dynamic> payload) => signImpl(payload);
}
