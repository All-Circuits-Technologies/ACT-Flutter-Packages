// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// A request which carries every parameter a call can be given.
RequestParam _fullRequest() => RequestParam(
  httpMethod: HttpMethods.post,
  relativeRoute: "items/{id}",
  headers: {"X-Token": "a token"},
  routeParams: {"{id}": "7"},
  queryParameters: {"page": "2"},
  body: "a body",
  encoding: utf8,
  timeout: const Duration(seconds: 5),
  requestMimeType: HttpMimeTypes.plainText,
  expectedMimeType: HttpMimeTypes.json,
);

void main() {
  group("RequestParam", () {
    test("carries no header when the call gave none", () {
      final request = RequestParam(httpMethod: HttpMethods.get, relativeRoute: "items");

      expect(request.headers, isEmpty);
    });

    test("is the same request as another one which carries the same parameters", () {
      expect(_fullRequest(), _fullRequest());
    });

    test("is another request as soon as one parameter differs", () {
      expect(
        _fullRequest(),
        isNot(_fullRequest().copyWith(relativeRoute: "tags")),
      );
    });

    test("is the same request as one which only differs by its timeout", () {
      // The timeout is not part of what makes a request, it says how long we wait for its answer
      expect(
        _fullRequest(),
        _fullRequest().copyWith(timeout: const Duration(minutes: 1)),
      );
    });
  });

  group("RequestParam.copyWith", () {
    test("keeps every parameter which is not named", () {
      final request = _fullRequest();

      final copy = request.copyWith();

      expect(copy.httpMethod, request.httpMethod);
      expect(copy.relativeRoute, request.relativeRoute);
      expect(copy.headers, request.headers);
      expect(copy.routeParams, request.routeParams);
      expect(copy.queryParameters, request.queryParameters);
      expect(copy.body, request.body);
      expect(copy.encoding, request.encoding);
      expect(copy.timeout, request.timeout);
      expect(copy.requestMimeType, request.requestMimeType);
      expect(copy.expectedMimeType, request.expectedMimeType);
    });

    test("replaces the parameters which are named", () {
      final copy = _fullRequest().copyWith(
        httpMethod: HttpMethods.get,
        relativeRoute: "tags",
        headers: {"X-Token": "another token"},
        routeParams: {"{id}": "8"},
        queryParameters: {"page": "3"},
        body: "another body",
        encoding: latin1,
        timeout: const Duration(seconds: 10),
        requestMimeType: HttpMimeTypes.json,
        expectedMimeType: HttpMimeTypes.plainText,
      );

      expect(copy.httpMethod, HttpMethods.get);
      expect(copy.relativeRoute, "tags");
      expect(copy.headers, {"X-Token": "another token"});
      expect(copy.routeParams, {"{id}": "8"});
      expect(copy.queryParameters, {"page": "3"});
      expect(copy.body, "another body");
      expect(copy.encoding, latin1);
      expect(copy.timeout, const Duration(seconds: 10));
      expect(copy.requestMimeType, HttpMimeTypes.json);
      expect(copy.expectedMimeType, HttpMimeTypes.plainText);
    });

    test("forgets the parameters of the route the copy is asked to force", () {
      final copy = _fullRequest().copyWith(forceRouteParams: true);

      expect(copy.routeParams, isNull);
    });

    test("forgets the query parameters the copy is asked to force", () {
      final copy = _fullRequest().copyWith(forceQueryParameters: true);

      expect(copy.queryParameters, isNull);
    });

    test("forgets the body the copy is asked to force", () {
      final copy = _fullRequest().copyWith(forceBody: true);

      expect(copy.body, isNull);
    });

    test("forgets the encoding the copy is asked to force", () {
      final copy = _fullRequest().copyWith(forceEncoding: true);

      expect(copy.encoding, isNull);
    });

    test("forgets the timeout the copy is asked to force", () {
      final copy = _fullRequest().copyWith(forceTimeout: true);

      expect(copy.timeout, isNull);
    });

    test("forgets the MIME type of the request the copy is asked to force", () {
      final copy = _fullRequest().copyWith(forceRequestMimeType: true);

      expect(copy.requestMimeType, isNull);
    });

    test("forgets the expected MIME type the copy is asked to force", () {
      final copy = _fullRequest().copyWith(forceExpectedMimeType: true);

      expect(copy.expectedMimeType, isNull);
    });

    test("keeps a parameter which is both named and forced", () {
      final copy = _fullRequest().copyWith(body: "another body", forceBody: true);

      expect(copy.body, "another body");
    });
  });
}
