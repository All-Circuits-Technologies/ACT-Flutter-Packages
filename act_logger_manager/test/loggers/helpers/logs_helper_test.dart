// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_external_logger.dart';

void main() {
  late FakeExternalLogger external;

  setUp(() => external = FakeExternalLogger());

  /// Builds the helper under test.
  LogsHelper helper({String? category, LogsLevel? minLevel, LogsLevel? defaultLogLevel}) =>
      LogsHelper.withExternalLogger(
        externalLogger: external,
        category: category,
        minLevel: minLevel,
        defaultLogLevel: defaultLogLevel ?? LogsLevel.debug,
      );

  group("LogsHelper.log", () {
    test("gives the message to its external logger", () {
      helper().log("a message", level: LogsLevel.warn);

      expect(external.records.length, 1);
      expect(external.records.first.message, "a message");
      expect(external.records.first.level, LogsLevel.warn);
    });

    test("gives the error and the stack trace to its external logger", () {
      final stackTrace = StackTrace.fromString("a stack trace");

      helper().log("a message", level: LogsLevel.error, error: "an error", stackTrace: stackTrace);

      expect(external.records.first.error, "an error");
      expect(external.records.first.stackTrace, stackTrace);
    });

    test("gives its categories to its external logger", () {
      helper(category: "manager").log("a message", level: LogsLevel.warn);

      expect(external.records.first.categories, ["manager"]);
    });

    test("gives no category when it has none", () {
      helper().log("a message", level: LogsLevel.warn);

      expect(external.records.first.categories, isEmpty);
    });

    test("stamps the message with the time it is logged at", () {
      final before = DateTime.now();

      helper().log("a message", level: LogsLevel.warn);

      final time = external.records.first.time;
      expect(time, isNotNull);
      expect(time!.isBefore(before), isFalse);
    });

    test("drops a message below its minimum level", () {
      helper(minLevel: LogsLevel.warn).log("a message", level: LogsLevel.info);

      expect(external.records, isEmpty);
    });

    test("keeps a message of its minimum level", () {
      helper(minLevel: LogsLevel.warn).log("a message", level: LogsLevel.warn);

      expect(external.records.length, 1);
    });

    test("leaves the filtering to its external logger when it has no minimum level", () {
      external.minLevel = LogsLevel.error;

      helper().log("a message", level: LogsLevel.info);

      expect(external.records.length, 1);
    });
  });

  group("LogsHelper.logMessages", () {
    test("logs at its default level", () {
      helper(defaultLogLevel: LogsLevel.info).logMessages("a message");

      expect(external.records.first.level, LogsLevel.info);
    });

    test("logs at the debug level by default", () {
      helper().logMessages("a message");

      expect(external.records.first.level, LogsLevel.debug);
    });
  });

  group("LogsHelper.createSubLogger", () {
    test("appends its sub category to the categories of its parent", () {
      final parent = helper(category: "manager");

      parent.createSubLogger(subCategory: "http").log("a message", level: LogsLevel.warn);

      expect(external.records.first.categories, ["manager", "http"]);
    });

    test("can be chained", () {
      final parent = helper(category: "manager");

      parent
          .createSubLogger(subCategory: "http")
          .createSubLogger(subCategory: "retry")
          .log("a message", level: LogsLevel.warn);

      expect(external.records.first.categories, ["manager", "http", "retry"]);
    });

    test("logs through the external logger of its parent", () {
      final sub = helper().createSubLogger(subCategory: "http");

      sub.log("a message", level: LogsLevel.warn);

      expect(external.records.length, 1);
    });

    test("keeps the minimum level of its parent", () {
      final sub = helper(minLevel: LogsLevel.error).createSubLogger(subCategory: "http");

      sub.log("a message", level: LogsLevel.warn);

      expect(external.records, isEmpty);
    });

    test("keeps the default level of its parent", () {
      final sub = helper(defaultLogLevel: LogsLevel.info).createSubLogger(subCategory: "http");

      sub.logMessages("a message");

      expect(external.records.first.level, LogsLevel.info);
    });
  });

  group("LogsHelper.createSubLoggerMinLevel", () {
    test("logs at the minimum level it is given rather than the one of its parent", () {
      final parent = helper(minLevel: LogsLevel.error);

      parent
          .createSubLoggerMinLevel(subCategory: "http", minLevel: LogsLevel.info)
          .log("a message", level: LogsLevel.warn);

      expect(external.records.length, 1);
    });

    test("keeps the minimum level of its parent when it is given none", () {
      final parent = helper(minLevel: LogsLevel.error);

      parent
          .createSubLoggerMinLevel(subCategory: "http")
          .log("a message", level: LogsLevel.warn);

      expect(external.records, isEmpty);
    });
  });

  group("LogsHelper.createAbsSubLogger", () {
    test("creates a sub logger of the same kind", () {
      expect(helper().createAbsSubLogger(subCategory: "http"), isA<LogsHelper>());
    });

    test("appends its sub category to the categories of its parent", () {
      helper(
        category: "manager",
      ).createAbsSubLogger(subCategory: "http").log("a message", level: LogsLevel.warn);

      expect(external.records.first.categories, ["manager", "http"]);
    });

    test("overrides the minimum level of its parent when one is given", () {
      helper(minLevel: LogsLevel.error)
          .createAbsSubLoggerMinLevel(subCategory: "http", minLevel: LogsLevel.info)
          .log("a message", level: LogsLevel.warn);

      expect(external.records.length, 1);
    });
  });

  group("LogsHelper.wouldBeLogged", () {
    test("returns false for a level below its minimum level", () {
      expect(helper(minLevel: LogsLevel.warn).wouldBeLogged(LogsLevel.info), isFalse);
    });

    test("asks its external logger when the level passes its minimum level", () {
      external.minLevel = LogsLevel.error;

      expect(helper(minLevel: LogsLevel.info).wouldBeLogged(LogsLevel.warn), isFalse);
    });

    test("returns true when both it and its external logger accept the level", () {
      external.minLevel = LogsLevel.info;

      expect(helper(minLevel: LogsLevel.info).wouldBeLogged(LogsLevel.warn), isTrue);
    });
  });

  group("LogsHelper", () {
    test("logs at the level of the method which is called", () {
      final logsHelper = helper()
        ..t("trace")
        ..d("debug")
        ..i("info")
        ..w("warn")
        ..e("error")
        ..f("fatal");

      expect(logsHelper.externalLogger, external);
      expect(external.records.map((record) => record.level), [
        LogsLevel.trace,
        LogsLevel.debug,
        LogsLevel.info,
        LogsLevel.warn,
        LogsLevel.error,
        LogsLevel.fatal,
      ]);
    });
  });
}
