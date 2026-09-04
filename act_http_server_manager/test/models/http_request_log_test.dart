// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HttpRequestLog.requestNow", () {
    final request = Request("POST", Uri.parse("http://a.host/api/item"));

    test("reads the method and the route of the request", () {
      final log = HttpRequestLog.requestNow(
        requestId: "a request",
        request: request,
        logLevel: LogsLevel.info,
        message: "a message",
      );

      expect(log.method, "POST");
      expect(log.route, "api/item");
    });

    test("stamps the log with the moment it was written", () {
      final before = DateTime.now().toUtc();

      final log = HttpRequestLog.requestNow(
        requestId: "a request",
        request: request,
        logLevel: LogsLevel.info,
        message: "a message",
      );

      expect(log.timestamp.isBefore(before), isFalse);
      expect(log.timestamp.isUtc, isTrue);
    });
  });

  group("HttpRequestLog.now", () {
    test("writes the route and the method it is given", () {
      final log = HttpRequestLog.now(
        requestId: "a request",
        route: "/api/item",
        method: "GET",
        logLevel: LogsLevel.info,
        message: "a message",
      );

      expect(log.route, "/api/item");
      expect(log.method, "GET");
    });
  });
}
