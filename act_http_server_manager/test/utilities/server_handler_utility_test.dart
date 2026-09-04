// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_http_server_manager/src/utilities/server_handler_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart' show Handler;

import '../fakes/fake_server.dart';

void main() {
  late FakeHttpLogging logging;
  late List<String> calls;

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
    calls = [];
  });

  /// The request the tests send to the route.
  Request aRequest() => Request("GET", Uri.parse("http://a.host/api/item"));

  /// The route the tests call, which records the header it was given, if it was given one.
  Handler aRoute({List<String>? headers}) => (request) {
    calls.add("the route");
    headers?.add(request.headers["a-header"] ?? "none");

    return Response.ok("from the route");
  };

  group("ServerHandlersUtility.manageServerHandlers", () {
    test("calls the route of a request which goes through no handler", () async {
      final response = await ServerHandlersUtility.manageServerHandlers(
        request: aRequest(),
        innerHandler: aRoute(),
        routeHandlers: [],
      );

      expect(await response.readAsString(), "from the route");
    });

    test("calls the handlers before the route and unwinds them after it", () async {
      await ServerHandlersUtility.manageServerHandlers(
        request: aRequest(),
        innerHandler: aRoute(),
        routeHandlers: [
          FakeServerHandler(httpLoggingManager: logging, calls: calls, name: "first"),
          FakeServerHandler(httpLoggingManager: logging, calls: calls, name: "second"),
        ],
      );

      expect(calls, ["first.before", "second.before", "the route", "second.after", "first.after"]);
    });

    test("hands the route the request the handlers changed", () async {
      final headers = <String>[];

      await ServerHandlersUtility.manageServerHandlers(
        request: aRequest(),
        innerHandler: aRoute(headers: headers),
        routeHandlers: [
          FakeServerHandler(
            httpLoggingManager: logging,
            calls: calls,
            addedHeader: const MapEntry("a-header", "a value"),
          ),
        ],
      );

      expect(headers, ["a value"]);
    });

    test("hands the next handler the request the previous one changed", () async {
      final headers = <String>[];

      await ServerHandlersUtility.manageServerHandlers(
        request: aRequest(),
        innerHandler: aRoute(headers: headers),
        routeHandlers: [
          FakeServerHandler(
            httpLoggingManager: logging,
            calls: calls,
            name: "first",
            addedHeader: const MapEntry("a-header", "the first value"),
          ),
          FakeServerHandler(
            httpLoggingManager: logging,
            calls: calls,
            name: "second",
            addedHeader: const MapEntry("a-header", "the second value"),
          ),
        ],
      );

      expect(headers, ["the second value"]);
    });

    test("answers with the response a handler forced, without calling the route", () async {
      final response = await ServerHandlersUtility.manageServerHandlers(
        request: aRequest(),
        innerHandler: aRoute(),
        routeHandlers: [
          FakeServerHandler(
            httpLoggingManager: logging,
            calls: calls,
            name: "first",
            forcedResponse: Response.forbidden("no"),
          ),
          FakeServerHandler(httpLoggingManager: logging, calls: calls, name: "second"),
        ],
      );

      expect(response.statusCode, 403);
      expect(calls, ["first.before"]);
    });

    test("hands the handlers the response the route answered with", () async {
      final response = await ServerHandlersUtility.manageServerHandlers(
        request: aRequest(),
        innerHandler: aRoute(),
        routeHandlers: [
          FakeServerHandler(
            httpLoggingManager: logging,
            calls: calls,
            addedResponseHeader: const MapEntry("a-header", "a value"),
          ),
        ],
      );

      expect(response.headers["a-header"], "a value");
    });
  });
}
