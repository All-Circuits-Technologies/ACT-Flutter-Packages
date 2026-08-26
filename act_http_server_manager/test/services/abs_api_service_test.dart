// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart' show Middleware;

import '../fakes/fake_server.dart';

/// The configuration of a server which answers on the root of its host.
const _rootConfig = HttpServerConfig(serverName: "a server", hostname: "127.0.0.1", port: 0);

void main() {
  late FakeHttpLogging logging;

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
  });

  /// The service of a server which answers under [basePath], on the routes under
  /// [serviceRelativePath].
  FakeApiService aService({String? basePath, String? serviceRelativePath}) => FakeApiService(
    httpLoggingManager: logging,
    config: HttpServerConfig(
      serverName: "a server",
      hostname: "127.0.0.1",
      port: 0,
      basePath: basePath,
    ),
    serviceRelativePath: serviceRelativePath,
  );

  /// The request which sends [body] to the service.
  Request aRequestWith(String body) =>
      Request("POST", Uri.parse("http://a.host/object"), body: body);

  group("AbsApiService.serviceBasePath", () {
    test("answers on the root of the host when the server has no base path", () {
      expect(aService().serviceBasePath, "/");
    });

    test("adds the separators a base path is missing", () {
      expect(aService(basePath: "api").serviceBasePath, "/api/");
    });

    test("keeps the separators a base path already has", () {
      expect(aService(basePath: "/api/").serviceBasePath, "/api/");
    });

    test("joins the path of the service to the one of the server", () {
      final service = aService(basePath: "/api", serviceRelativePath: "item");

      expect(service.serviceBasePath, "/api/item/");
    });

    test("joins two paths which both carry the separator only once", () {
      final service = aService(basePath: "/api/", serviceRelativePath: "/item");

      expect(service.serviceBasePath, "/api/item/");
    });

    test("joins two paths of which only one carries the separator", () {
      final service = aService(basePath: "/api/", serviceRelativePath: "item");

      expect(service.serviceBasePath, "/api/item/");
    });

    test("gives the service of a server without base path its own path", () {
      expect(aService(serviceRelativePath: "item").serviceBasePath, "/item/");
    });
  });

  group("AbsApiService.initRoutes", () {
    test("remembers every route it registered, under the path of the service", () async {
      final service = aService(basePath: "/api");
      await service.initRoutes(Router());

      expect(service.registeredRoutes.first.pathSegments, ["api", "hello"]);
      expect(
        service.registeredRoutes.map((route) => route.method).toSet(),
        HttpMethods.values.toSet(),
      );
    });

    test("answers on the routes it registered", () async {
      final router = Router();
      await aService().initRoutes(router);

      final response = await router.call(Request("GET", Uri.parse("http://a.host/hello")));

      expect(await response.readAsString(), "hello");
    });

    test("hands the route the part of the path which identifies what is asked for", () async {
      final router = Router();
      await aService().initRoutes(router);

      final response = await router.call(Request("GET", Uri.parse("http://a.host/item/123")));

      expect(await response.readAsString(), "123");
    });

    test("calls the handlers of a route before the route answers", () async {
      final calls = <String>[];
      final service = FakeApiService(
        httpLoggingManager: logging,
        config: _rootConfig,
        routeHandlers: [FakeServerHandler(httpLoggingManager: logging, calls: calls)],
      );
      final router = Router();
      await service.initRoutes(router);

      await router.call(Request("GET", Uri.parse("http://a.host/hello")));

      expect(calls, ["a handler.before", "a handler.after"]);
    });
  });

  group("AbsApiService.getJsonObjectBody", () {
    test("reads the object the request carries", () async {
      final service = aService();

      final body = await service.readObjectBody(aRequestWith('{"aKey": "a value"}'));

      expect(body, {"aKey": "a value"});
    });

    test("reads nothing from a body which is not json", () async {
      final service = aService();

      expect(await service.readObjectBody(aRequestWith("not json")), isNull);
    });

    test("writes why it could not read a body which is not json", () async {
      await aService().readObjectBody(aRequestWith("not json"));

      expect(logging.logs.single.logLevel, LogsLevel.error);
    });

    test("reads nothing from a body which carries a list", () async {
      final service = aService();

      expect(await service.readObjectBody(aRequestWith('["a value"]')), isNull);
    });

    test("writes why it could not read a body which carries the wrong shape", () async {
      await aService().readObjectBody(aRequestWith('["a value"]'));

      expect(logging.logs.single.logLevel, LogsLevel.warn);
    });
  });

  group("AbsApiService.getParsedJsonObjectBody", () {
    test("builds the value the parser reads from the body", () async {
      final service = aService();

      final value = await service.readParsedObjectBody<String>(
        aRequestWith('{"aKey": "a value"}'),
        (json) => json["aKey"] as String?,
      );

      expect(value, "a value");
    });

    test("reads nothing when the parser refuses the body", () async {
      final service = aService();

      final value = await service.readParsedObjectBody<String>(
        aRequestWith('{"aKey": "a value"}'),
        (json) => null,
      );

      expect(value, isNull);
      expect(logging.logs.single.logLevel, LogsLevel.warn);
    });

    test("reads nothing when the body could not be read at all", () async {
      final service = aService();

      final value = await service.readParsedObjectBody<String>(
        aRequestWith("not json"),
        (json) => "a value",
      );

      expect(value, isNull);
    });
  });

  group("AbsApiService.getJsonArrayBody", () {
    test("reads the list the request carries", () async {
      final service = aService();

      expect(await service.readArrayBody(aRequestWith('["a value"]')), ["a value"]);
    });

    test("reads nothing from a body which carries an object", () async {
      final service = aService();

      expect(await service.readArrayBody(aRequestWith('{"aKey": "a value"}')), isNull);
    });
  });

  group("AbsApiService.getParsedJsonArrayBody", () {
    test("builds a value out of every element of the list", () async {
      final service = aService();

      final values = await service.readParsedArrayBody<String>(
        aRequestWith('[{"aKey": "first"}, {"aKey": "second"}]'),
        (json) => json["aKey"] as String?,
      );

      expect(values, ["first", "second"]);
    });

    test("reads nothing when an element of the list is not an object", () async {
      final service = aService();

      final values = await service.readParsedArrayBody<String>(
        aRequestWith('[{"aKey": "first"}, "second"]'),
        (json) => json["aKey"] as String?,
      );

      expect(values, isNull);
      expect(logging.logs.single.logLevel, LogsLevel.warn);
    });

    test("reads nothing when the parser refuses one element of the list", () async {
      final service = aService();

      final values = await service.readParsedArrayBody<String>(
        aRequestWith('[{"aKey": "first"}, {"anotherKey": "second"}]'),
        (json) => json["aKey"] as String?,
      );

      expect(values, isNull);
    });

    test("reads an empty list from a body which carries one", () async {
      final service = aService();

      final values = await service.readParsedArrayBody<String>(
        aRequestWith("[]"),
        (json) => json["aKey"] as String?,
      );

      expect(values, isEmpty);
    });
  });

  group("AbsApiService.manageMiddlewares", () {
    test("calls the middlewares around the route, in the order they are given", () async {
      final calls = <String>[];
      Middleware aMiddleware(String name) =>
          (innerHandler) => (request) async {
            calls.add("$name.before");
            final response = await innerHandler(request);
            calls.add("$name.after");

            return response;
          };
      Response route(Request request) {
        calls.add("the route");

        return Response.ok(null);
      }

      final handler = aService().wrapInMiddlewares(route, [
        aMiddleware("first"),
        aMiddleware("second"),
      ]);
      await handler(Request("GET", Uri.parse("http://a.host/hello")));

      expect(calls, ["first.before", "second.before", "the route", "second.after", "first.after"]);
    });

    test("calls the route of a handler which is wrapped in no middleware", () async {
      final handler = aService().wrapInMiddlewares((request) => Response.ok("from the route"), []);

      final response = await handler(Request("GET", Uri.parse("http://a.host/hello")));

      expect(await response.readAsString(), "from the route");
    });
  });

  group("AbsApiService", () {
    test("reads the body of a request through the route which answers it", () async {
      final service = aService();
      final router = Router();
      await service.initRoutes(router);

      final response = await router.call(
        Request("POST", Uri.parse("http://a.host/object"), body: jsonEncode({"aKey": "a value"})),
      );

      expect(response.statusCode, 200);
      expect(service.readBodies, [
        {"aKey": "a value"},
      ]);
    });

    test("turns away a request whose body the route could not read", () async {
      final service = aService();
      final router = Router();
      await service.initRoutes(router);

      final response = await router.call(
        Request("POST", Uri.parse("http://a.host/array"), body: "not json"),
      );

      expect(response.statusCode, 400);
    });
  });
}
