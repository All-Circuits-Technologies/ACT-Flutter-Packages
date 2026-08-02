// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeExternalLogger logger;

  setUp(() => logger = FakeExternalLogger());

  group("FakeExternalLogger.log", () {
    test("records the message it is given", () {
      logger.log(message: "something happened", level: LogsLevel.info);

      expect(logger.records.single.message, "something happened");
    });

    test("records the level, the categories, the error and the stack trace", () {
      final stackTrace = StackTrace.current;

      logger.log(
        message: "it failed",
        level: LogsLevel.error,
        error: "the reason",
        stackTrace: stackTrace,
        categories: const ["manager", "sub"],
      );

      expect(logger.records, [
        FakeLogRecord(
          categories: const ["manager", "sub"],
          level: LogsLevel.error,
          message: "it failed",
          error: "the reason",
          stackTrace: stackTrace,
        ),
      ]);
    });

    test("records the messages in the order they were logged", () {
      logger
        ..log(message: "first", level: LogsLevel.info)
        ..log(message: "second", level: LogsLevel.info);

      expect(logger.records.map((record) => record.message), ["first", "second"]);
    });

    test("drops a message logged below the minimum level", () {
      logger = FakeExternalLogger(minLevel: LogsLevel.warn);

      logger.log(message: "a detail", level: LogsLevel.debug);

      expect(logger.records, isEmpty);
    });
  });

  group("FakeExternalLogger.recordsAtLevel", () {
    test("keeps only the messages of the level given", () {
      logger
        ..log(message: "a detail", level: LogsLevel.debug)
        ..log(message: "a problem", level: LogsLevel.warn);

      expect(logger.recordsAtLevel(LogsLevel.warn).single.message, "a problem");
    });
  });

  group("FakeExternalLogger.clearRecords", () {
    test("forgets the messages logged before the call", () {
      logger.log(message: "a detail", level: LogsLevel.debug);

      logger.clearRecords();

      expect(logger.records, isEmpty);
    });
  });

  group("FakeExternalLogger.buildHelper", () {
    test("builds a helper which records what a class under test logs", () {
      final helper = logger.buildHelper(category: "myManager");

      helper.w("a problem");

      expect(logger.recordsAtLevel(LogsLevel.warn).single.message, "a problem");
    });

    test("builds a helper which records the category it was built with", () {
      final helper = logger.buildHelper(category: "myManager");

      helper.i("something happened");

      expect(logger.records.single.categories, ["myManager"]);
    });

    test("builds a helper which drops the messages below its own minimum level", () {
      final helper = logger.buildHelper(minLevel: LogsLevel.warn);

      helper.d("a detail");

      expect(logger.records, isEmpty);
    });
  });

  group("FakeExternalLogger.wouldBeLogged", () {
    test("returns true for a level above the minimum one", () {
      logger = FakeExternalLogger(minLevel: LogsLevel.warn);

      expect(logger.wouldBeLogged(level: LogsLevel.error), isTrue);
    });

    test("returns false for a level below the minimum one", () {
      logger = FakeExternalLogger(minLevel: LogsLevel.warn);

      expect(logger.wouldBeLogged(level: LogsLevel.debug), isFalse);
    });
  });
}
