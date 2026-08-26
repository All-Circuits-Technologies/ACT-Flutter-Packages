// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SilentLogger.log", () {
    test("accepts a message at any level without throwing", () {
      const logger = SilentLogger();

      expect(() {
        for (final level in LogsLevel.values) {
          logger.log("a message", level: level);
        }
      }, returnsNormally);
    });

    test("accepts a message with an error and a stack trace without throwing", () {
      const logger = SilentLogger();

      expect(
        () => logger.log(
          "a message",
          level: LogsLevel.error,
          error: Exception("boom"),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });

  group("SilentLogger.logMessages", () {
    test("accepts a message without throwing", () {
      const logger = SilentLogger();

      expect(() => logger.logMessages("a message"), returnsNormally);
    });
  });

  group("SilentLogger.createAbsSubLogger", () {
    test("returns a silent logger", () {
      const logger = SilentLogger();

      expect(logger.createAbsSubLogger(subCategory: "sub"), isA<SilentLogger>());
    });
  });

  group("SilentLogger.createAbsSubLoggerMinLevel", () {
    test("returns a silent logger", () {
      const logger = SilentLogger();

      expect(
        logger.createAbsSubLoggerMinLevel(subCategory: "sub", minLevel: LogsLevel.error),
        isA<SilentLogger>(),
      );
    });
  });

  group("SilentLogger.wouldBeLogged", () {
    test("returns false for every level", () {
      const logger = SilentLogger();

      expect(LogsLevel.values.every(logger.wouldBeLogged), isFalse);
    });
  });
}
