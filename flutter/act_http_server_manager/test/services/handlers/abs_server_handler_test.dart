// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_server.dart';

void main() {
  late BareServerHandler handler;
  late FakeHttpLogging logging;

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
    handler = BareServerHandler(httpLoggingManager: logging);
  });

  final request = Request("GET", Uri.parse("http://a.host/api/item"));

  group("AbsServerHandler.beforeHandler", () {
    test("lets the request reach the route as it is", () async {
      final result = await handler.beforeHandler(request: request);

      expect(result.forceResponse, isNull);
      expect(result.overrideRequest, isNull);
    });
  });

  group("AbsServerHandler.afterHandler", () {
    test("lets the response of the route through as it is", () async {
      final response = Response.ok("from the route");

      expect(await handler.afterHandler(request: request, response: response), response);
    });
  });

  group("AbsServerHandler.httpLoggingManager", () {
    test("writes to the logging manager it was built with", () {
      expect(handler.httpLoggingManager, logging);
    });
  });
}
