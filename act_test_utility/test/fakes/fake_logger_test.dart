// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FakeLogger.log", () {
    test("records the message with its level", () {
      final logger = FakeLogger();

      logger.log("a message", level: LogsLevel.warn);

      expect(logger.records.length, 1);
      expect(logger.records.first.message, "a message");
      expect(logger.records.first.level, LogsLevel.warn);
    });

    test("records the error and the stack trace given with the message", () {
      final logger = FakeLogger();
      final error = Exception("boom");
      final stackTrace = StackTrace.current;

      logger.log("a message", level: LogsLevel.error, error: error, stackTrace: stackTrace);

      expect(logger.records.first.error, error);
      expect(logger.records.first.stackTrace, stackTrace);
    });

    test("records the messages in the order they were logged", () {
      final logger = FakeLogger();

      logger
        ..log("first", level: LogsLevel.info)
        ..log("second", level: LogsLevel.info);

      expect(logger.records.map((record) => record.message), ["first", "second"]);
    });

    test("records the category of the logger", () {
      final logger = FakeLogger(category: "main");

      logger.log("a message", level: LogsLevel.info);

      expect(logger.records.first.categories, ["main"]);
    });

    test("drops the message when its level is lower than the minimum level", () {
      final logger = FakeLogger(minLevel: LogsLevel.warn);

      logger.log("a message", level: LogsLevel.debug);

      expect(logger.records, isEmpty);
    });

    test("records the message when its level is the minimum level", () {
      final logger = FakeLogger(minLevel: LogsLevel.warn);

      logger.log("a message", level: LogsLevel.warn);

      expect(logger.records.length, 1);
    });
  });

  group("FakeLogger level helpers", () {
    test("records the message at the level of the called helper", () {
      final logger = FakeLogger();

      logger
        ..t("trace")
        ..d("debug")
        ..i("info")
        ..w("warn")
        ..e("error")
        ..f("fatal");

      expect(logger.records.map((record) => record.level), [
        LogsLevel.trace,
        LogsLevel.debug,
        LogsLevel.info,
        LogsLevel.warn,
        LogsLevel.error,
        LogsLevel.fatal,
      ]);
    });
  });

  group("FakeLogger.logMessages", () {
    test("records the message at the default level", () {
      final logger = FakeLogger(defaultLogLevel: LogsLevel.info);

      logger.logMessages("a message");

      expect(logger.records.first.level, LogsLevel.info);
    });

    test("records the message at the debug level when no default level is given", () {
      final logger = FakeLogger();

      logger.logMessages("a message");

      expect(logger.records.first.level, LogsLevel.debug);
    });
  });

  group("FakeLogger.records", () {
    test("returns a view which cannot be modified by the test", () {
      final logger = FakeLogger();

      expect(
        () => logger.records.add(
          const FakeLogRecord(categories: [], level: LogsLevel.info, message: "a message"),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group("FakeLogger.recordsAtLevel", () {
    test("returns only the messages logged at the given level", () {
      final logger = FakeLogger();

      logger
        ..i("an info")
        ..w("a warning")
        ..i("another info");

      expect(logger.recordsAtLevel(LogsLevel.info).map((record) => record.message), [
        "an info",
        "another info",
      ]);
    });

    test("returns an empty list when no message was logged at the given level", () {
      final logger = FakeLogger()..i("an info");

      expect(logger.recordsAtLevel(LogsLevel.error), isEmpty);
    });
  });

  group("FakeLogger.clearRecords", () {
    test("forgets the messages logged before the call", () {
      final logger = FakeLogger()..i("an info");

      logger.clearRecords();

      expect(logger.records, isEmpty);
    });

    test("forgets the messages logged by the sub loggers", () {
      final logger = FakeLogger();
      final subLogger = logger.createAbsSubLogger(subCategory: "sub")..i("an info");

      logger.clearRecords();

      expect(subLogger.records, isEmpty);
    });
  });

  group("FakeLogger.createAbsSubLogger", () {
    test("appends the sub category to the categories of the parent logger", () {
      final logger = FakeLogger(category: "main");

      final subLogger = logger.createAbsSubLogger(subCategory: "sub");

      expect(subLogger.categories, ["main", "sub"]);
    });

    test("shares the records with the parent logger", () {
      final logger = FakeLogger(category: "main");

      logger.createAbsSubLogger(subCategory: "sub").i("an info");

      expect(logger.records.first.categories, ["main", "sub"]);
    });

    test("keeps the minimum level of the parent logger", () {
      final logger = FakeLogger(minLevel: LogsLevel.warn);

      final subLogger = logger.createAbsSubLogger(subCategory: "sub");

      expect(subLogger.minLevel, LogsLevel.warn);
    });

    test("keeps the default level of the parent logger", () {
      final logger = FakeLogger(defaultLogLevel: LogsLevel.error);

      final subLogger = logger.createAbsSubLogger(subCategory: "sub");

      expect(subLogger.defaultLogLevel, LogsLevel.error);
    });
  });

  group("FakeLogger.createAbsSubLoggerMinLevel", () {
    test("overrides the minimum level of the parent logger", () {
      final logger = FakeLogger(minLevel: LogsLevel.debug);

      final subLogger = logger.createAbsSubLoggerMinLevel(
        subCategory: "sub",
        minLevel: LogsLevel.error,
      );

      expect(subLogger.minLevel, LogsLevel.error);
    });

    test("keeps the minimum level of the parent logger when no level is given", () {
      final logger = FakeLogger(minLevel: LogsLevel.debug);

      final subLogger = logger.createAbsSubLoggerMinLevel(subCategory: "sub");

      expect(subLogger.minLevel, LogsLevel.debug);
    });
  });

  group("FakeLogger.wouldBeLogged", () {
    test("returns true for any level when no minimum level is set", () {
      final logger = FakeLogger();

      expect(logger.wouldBeLogged(LogsLevel.trace), isTrue);
    });

    test("returns false when the level is lower than the minimum level", () {
      final logger = FakeLogger(minLevel: LogsLevel.warn);

      expect(logger.wouldBeLogged(LogsLevel.info), isFalse);
    });

    test("returns true when the level is higher than the minimum level", () {
      final logger = FakeLogger(minLevel: LogsLevel.warn);

      expect(logger.wouldBeLogged(LogsLevel.fatal), isTrue);
    });
  });
}
