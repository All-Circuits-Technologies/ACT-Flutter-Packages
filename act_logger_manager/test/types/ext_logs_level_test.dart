// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/src/types/ext_logs_level.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  group("ExtLogsLevel.toLoggerLevel", () {
    test("gives the level of the logger package which matches", () {
      expect(LogsLevel.all.toLoggerLevel, Level.all);
      expect(LogsLevel.trace.toLoggerLevel, Level.trace);
      expect(LogsLevel.debug.toLoggerLevel, Level.debug);
      expect(LogsLevel.info.toLoggerLevel, Level.info);
      expect(LogsLevel.warn.toLoggerLevel, Level.warning);
      expect(LogsLevel.error.toLoggerLevel, Level.error);
      expect(LogsLevel.fatal.toLoggerLevel, Level.fatal);
      expect(LogsLevel.off.toLoggerLevel, Level.off);
    });

    test("keeps the order of the levels", () {
      final converted = LogsLevel.values
          .map((level) => level.toLoggerLevel.value)
          .toList(growable: false);

      expect(converted, orderedEquals(List<int>.from(converted)..sort()));
    });
  });

  group("ExtLogsLevel.fromLoggerLevel", () {
    test("gives the level of the package which matches", () {
      expect(ExtLogsLevel.fromLoggerLevel(Level.all), LogsLevel.all);
      expect(ExtLogsLevel.fromLoggerLevel(Level.trace), LogsLevel.trace);
      expect(ExtLogsLevel.fromLoggerLevel(Level.debug), LogsLevel.debug);
      expect(ExtLogsLevel.fromLoggerLevel(Level.info), LogsLevel.info);
      expect(ExtLogsLevel.fromLoggerLevel(Level.warning), LogsLevel.warn);
      expect(ExtLogsLevel.fromLoggerLevel(Level.error), LogsLevel.error);
      expect(ExtLogsLevel.fromLoggerLevel(Level.fatal), LogsLevel.fatal);
      expect(ExtLogsLevel.fromLoggerLevel(Level.off), LogsLevel.off);
    });

    test("still reads the levels the logger package has deprecated", () {
      // The deprecated levels are covered on purpose: they are the ones a caller which has not
      // been updated yet gives
      // ignore: deprecated_member_use
      expect(ExtLogsLevel.fromLoggerLevel(Level.verbose), LogsLevel.trace);
      // The deprecated levels are covered on purpose
      // ignore: deprecated_member_use
      expect(ExtLogsLevel.fromLoggerLevel(Level.wtf), LogsLevel.fatal);
      // The deprecated levels are covered on purpose
      // ignore: deprecated_member_use
      expect(ExtLogsLevel.fromLoggerLevel(Level.nothing), LogsLevel.off);
    });

    test("gives back the level it started from", () {
      for (final level in LogsLevel.values) {
        expect(ExtLogsLevel.fromLoggerLevel(level.toLoggerLevel), level);
      }
    });
  });
}
