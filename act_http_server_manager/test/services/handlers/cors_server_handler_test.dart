// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_server.dart';

/// The configuration of the server the tests run.
const _config = HttpServerConfig(serverName: "a server", hostname: "127.0.0.1", port: 0);

void main() {
  late FakeHttpLogging logging;
  late FakeApiService service;

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
    service = FakeApiService(httpLoggingManager: logging, config: _config);
    await service.initRoutes(Router());
  });

  /// The handler of a server which answers on the routes of its service.
  CorsServerHandler aHandler({String? origin, String? methods, String? headers}) =>
      CorsServerHandler(
        httpLoggingManager: logging,
        apiServices: [service],
        accessControlAllowOriginValue: origin ?? CorsServerHandler.allowOriginAll,
        accessControlAllowMethodsValue: methods,
        accessControlAllowHeadersValue: headers,
      );

  /// The request of [method] on [path] a browser sends to the server.
  Request aRequest({String method = "OPTIONS", String path = "/hello"}) =>
      Request(method, Uri.parse("http://a.host$path"));

  group("CorsServerHandler.afterHandler", () {
    test("tells the browser which origin, methods and headers the server accepts", () async {
      final response = await aHandler().afterHandler(
        request: aRequest(method: "GET"),
        response: Response.ok(null),
      );

      expect(
        response.headers[HeaderConstants.accessControlAllowOriginHeaderKey],
        CorsServerHandler.allowOriginAll,
      );
      expect(
        response.headers[HeaderConstants.accessControlAllowMethodsHeaderKey],
        CorsServerHandler.allowMethodsAll,
      );
      expect(
        response.headers[HeaderConstants.accessControlAllowHeadersHeaderKey],
        CorsServerHandler.allowsGenericHeaders,
      );
    });

    test("tells the browser what the server was told to accept", () async {
      final handler = aHandler(origin: "https://a.site", methods: "GET", headers: "X-Token");

      final response = await handler.afterHandler(
        request: aRequest(method: "GET"),
        response: Response.ok(null),
      );

      expect(response.headers[HeaderConstants.accessControlAllowOriginHeaderKey], "https://a.site");
      expect(response.headers[HeaderConstants.accessControlAllowMethodsHeaderKey], "GET");
      expect(response.headers[HeaderConstants.accessControlAllowHeadersHeaderKey], "X-Token");
    });

    test("keeps the headers the route answered with", () async {
      final response = await aHandler().afterHandler(
        request: aRequest(method: "GET"),
        response: Response.ok(null, headers: {"a-header": "a value"}),
      );

      expect(response.headers["a-header"], "a value");
    });
  });

  group("CorsServerHandler.beforeHandler", () {
    test("lets a request which is not a preflight through", () async {
      final result = await aHandler().beforeHandler(request: aRequest(method: "GET"));

      expect(result.forceResponse, isNull);
      expect(result.overrideRequest, isNull);
    });

    test("answers the preflight of a route the server answers on", () async {
      final result = await aHandler().beforeHandler(request: aRequest());

      expect(result.forceResponse?.statusCode, 200);
    });

    test("tells the browser what it accepts when it answers a preflight", () async {
      final result = await aHandler().beforeHandler(request: aRequest());

      expect(
        result.forceResponse?.headers[HeaderConstants.accessControlAllowOriginHeaderKey],
        CorsServerHandler.allowOriginAll,
      );
    });

    test("answers the preflight of a route which holds an identifier", () async {
      final result = await aHandler().beforeHandler(request: aRequest(path: "/item/123"));

      expect(result.forceResponse?.statusCode, 200);
    });

    test("lets the preflight of a route the service answers itself through", () async {
      final result = await aHandler().beforeHandler(request: aRequest(path: "/options"));

      expect(result.forceResponse, isNull);
    });

    test("lets the preflight of a route the server does not answer on through", () async {
      final result = await aHandler().beforeHandler(request: aRequest(path: "/nothing"));

      expect(result.forceResponse, isNull);
    });
  });
}
