// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds the log of a request the application made.
HttpLog aLog({String? sourceInfo, String message = "the request went well"}) => HttpLog(
  timestamp: DateTime.utc(2024, 5, 17, 10, 30),
  requestId: "req-1",
  route: "/devices",
  method: "GET",
  logLevel: LogsLevel.info,
  message: message,
  sourceInfo: sourceInfo,
);

void main() {
  group("HttpLog.formattedLogMsg", () {
    test("writes the request, the route, the method and the message", () {
      expect(aLog().formattedLogMsg, "[req-1] - /devices - GET - the request went well");
    });

    test("writes the source before the request when the log carries one", () {
      expect(
        aLog(sourceInfo: "server").formattedLogMsg,
        "[server/req-1] - /devices - GET - the request went well",
      );
    });
  });

  group("HttpLog.now", () {
    test("stamps the log with the instant it is written, in UTC", () {
      final before = DateTime.now().toUtc();

      final log = HttpLog.now(
        requestId: "req-1",
        route: "/devices",
        method: "GET",
        logLevel: LogsLevel.info,
        message: "the request went well",
      );

      expect(log.timestamp.isUtc, isTrue);
      expect(log.timestamp.isBefore(before), isFalse);
    });

    test("carries no source unless the caller gives one", () {
      final log = HttpLog.now(
        requestId: "req-1",
        route: "/devices",
        method: "GET",
        logLevel: LogsLevel.info,
        message: "the request went well",
      );

      expect(log.sourceInfo, isNull);
    });
  });

  group("HttpLog.copyWith", () {
    test("replaces what it is given", () {
      expect(aLog().copyWith(message: "it failed").message, "it failed");
    });

    test("keeps what it is not given", () {
      final log = aLog(sourceInfo: "server");

      expect(log.copyWith(), log);
    });

    test("adds the source to a log which carried none", () {
      expect(aLog().copyWith(sourceInfo: "server").sourceInfo, "server");
    });
  });

  group("HttpLog", () {
    test("equals another log which carries the same values", () {
      expect(aLog(), aLog());
    });

    test("differs from a log of another message", () {
      expect(aLog(), isNot(aLog(message: "it failed")));
    });

    test("differs from a log which carries a source", () {
      expect(aLog(), isNot(aLog(sourceInfo: "server")));
    });
  });
}
