// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The route [method] and [path] identify.
HttpRouteListeningId _aRoute({
  HttpMethods method = HttpMethods.get,
  String path = "/api/item/<itemId>",
}) => HttpRouteListeningId.fromRouteListening(method: method, relativeRoute: path);

/// The route the request of [method] on [path] asks for.
HttpRouteListeningId _aRequest({String method = "GET", String path = "/api/item/123"}) =>
    HttpRouteListeningId.fromRequest(request: Request(method, Uri.parse("http://a.host$path")));

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("HttpRouteListeningId.fromRouteListening", () {
    test("cuts the route it listens on into its segments", () {
      expect(_aRoute().pathSegments, ["api", "item", "<itemId>"]);
    });

    test("drops the separators around the route", () {
      expect(_aRoute(path: "/api/").pathSegments, ["api"]);
    });

    test("keeps the method the route answers on", () {
      expect(_aRoute(method: HttpMethods.post).method, HttpMethods.post);
    });
  });

  group("HttpRouteListeningId.fromRequest", () {
    test("cuts the route of the request into its segments", () {
      expect(_aRequest().pathSegments, ["api", "item", "123"]);
    });

    test("reads the method of the request", () {
      expect(_aRequest(method: "POST").method, HttpMethods.post);
    });

    test("knows no method of a request which uses one it does not know", () {
      expect(_aRequest(method: "BREW").method, isNull);
    });

    test("warns about a method it does not know", () {
      _aRequest(method: "BREW");

      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
    });
  });

  group("HttpRouteListeningId.isSamePathSegments", () {
    test("holds a route and the request which asks for it for the same", () {
      expect(_aRoute().isSamePathSegments(_aRequest().pathSegments), isTrue);
    });

    test("takes the identifier of a route for whatever the request puts there", () {
      expect(_aRoute().isSamePathSegments(_aRequest(path: "/api/item/456").pathSegments), isTrue);
    });

    test("takes whatever the route puts where the request has an identifier", () {
      final route = _aRoute(path: "/api/item/123");

      expect(route.isSamePathSegments(const ["api", "item", "<itemId>"]), isTrue);
    });

    test("tells a route from a request which asks for another one", () {
      expect(_aRoute().isSamePathSegments(_aRequest(path: "/api/user/123").pathSegments), isFalse);
    });

    test("tells a route from a request which asks for a longer one", () {
      final request = _aRequest(path: "/api/item/123/detail");

      expect(_aRoute().isSamePathSegments(request.pathSegments), isFalse);
    });

    test("takes a segment which only starts like an identifier for a plain one", () {
      final route = _aRoute(path: "/api/<item");

      expect(route.isSamePathSegments(const ["api", "123"]), isFalse);
    });
  });

  group("HttpRouteListeningId", () {
    test("tells two routes which differ only by their method apart", () {
      expect(_aRoute(), isNot(_aRoute(method: HttpMethods.post)));
    });

    test("holds two routes which listen on the same path for equal", () {
      expect(_aRoute(), _aRoute());
    });
  });
}
