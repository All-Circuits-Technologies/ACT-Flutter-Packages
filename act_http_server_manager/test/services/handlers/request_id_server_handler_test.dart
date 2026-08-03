// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_server.dart';

void main() {
  late FakeHttpLogging logging;
  late RequestIdServerHandler handler;

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
    handler = RequestIdServerHandler(httpLoggingManager: logging);
  });

  /// The request the tests send to the server.
  Request aRequest() => Request("GET", Uri.parse("http://a.host/api/item"));

  group("RequestIdServerHandler.beforeHandler", () {
    test("marks the request with an identifier of its own", () async {
      final result = await handler.beforeHandler(request: aRequest());

      expect(RequestIdServerHandler.extractRequestId(result.overrideRequest!), isNotEmpty);
    });

    test("marks two requests apart", () async {
      final first = await handler.beforeHandler(request: aRequest());
      final second = await handler.beforeHandler(request: aRequest());

      expect(
        RequestIdServerHandler.extractRequestId(first.overrideRequest!),
        isNot(RequestIdServerHandler.extractRequestId(second.overrideRequest!)),
      );
    });

    test("lets the request through to the route", () async {
      final result = await handler.beforeHandler(request: aRequest());

      expect(result.forceResponse, isNull);
    });

    test("writes that the request was received", () async {
      await handler.beforeHandler(request: aRequest());

      expect(logging.messages, ["Received request"]);
      expect(logging.logs.single.logLevel, LogsLevel.info);
    });

    test("writes the log under the identifier it gave the request", () async {
      final result = await handler.beforeHandler(request: aRequest());

      expect(
        logging.logs.single.requestId,
        RequestIdServerHandler.extractRequestId(result.overrideRequest!),
      );
    });
  });

  group("RequestIdServerHandler.afterHandler", () {
    test("writes the status the server answered with", () async {
      final result = await handler.beforeHandler(request: aRequest());

      await handler.afterHandler(
        request: result.overrideRequest!,
        response: Response.notFound(null),
      );

      expect(logging.messages.last, "Responded with status code 404");
    });

    test("lets the response of the route through as it is", () async {
      final result = await handler.beforeHandler(request: aRequest());
      final response = Response.ok("from the route");

      final answered = await handler.afterHandler(
        request: result.overrideRequest!,
        response: response,
      );

      expect(answered, response);
    });
  });

  group("RequestIdServerHandler.tryToExtractRequestId", () {
    test("reads the identifier the handler gave the request", () async {
      final result = await handler.beforeHandler(request: aRequest());

      expect(RequestIdServerHandler.tryToExtractRequestId(result.overrideRequest!), isNotNull);
    });

    test("reads nothing from a request which went through no handler", () {
      expect(RequestIdServerHandler.tryToExtractRequestId(aRequest()), isNull);
    });
  });

  group("RequestIdServerHandler.tryToExtractRequestIdWithDefaultValue", () {
    test("names a request which went through no handler as unknown", () {
      expect(
        RequestIdServerHandler.tryToExtractRequestIdWithDefaultValue(aRequest()),
        RequestIdServerHandler.requestIdDefaultValue,
      );
    });
  });
}
