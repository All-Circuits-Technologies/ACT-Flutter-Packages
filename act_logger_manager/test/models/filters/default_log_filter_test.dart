// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/src/models/filters/default_log_filter.dart';
import 'package:act_logger_manager/src/types/ext_logs_level.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// Builds the event a message of the given [level] produces.
LogEvent _event(LogsLevel level) => LogEvent(level.toLoggerLevel, "a message");

void main() {
  group("DefaultLogFilter", () {
    test("keeps every message by default", () {
      final filter = DefaultLogFilter();

      expect(filter.minLevel, LogsLevel.all);
    });

    test("reports whether the application has been built in release mode", () {
      expect(DefaultLogFilter.isRelease, isFalse);
    });

    test("doesn't print in release by default", () {
      expect(DefaultLogFilter().printLogInRelease, isFalse);
    });
  });

  group("DefaultLogFilter.minLevel", () {
    test("gives back the level it was built with", () {
      final filter = DefaultLogFilter(minLevel: LogsLevel.warn);

      expect(filter.minLevel, LogsLevel.warn);
    });

    test("gives back the level it has been set to", () {
      final filter = DefaultLogFilter()..minLevel = LogsLevel.error;

      expect(filter.minLevel, LogsLevel.error);
    });
  });

  group("DefaultLogFilter.shouldLog", () {
    test("keeps a message of the minimum level", () {
      final filter = DefaultLogFilter(minLevel: LogsLevel.warn);

      expect(filter.shouldLog(_event(LogsLevel.warn)), isTrue);
    });

    test("keeps a message above the minimum level", () {
      final filter = DefaultLogFilter(minLevel: LogsLevel.warn);

      expect(filter.shouldLog(_event(LogsLevel.error)), isTrue);
    });

    test("drops a message below the minimum level", () {
      final filter = DefaultLogFilter(minLevel: LogsLevel.warn);

      expect(filter.shouldLog(_event(LogsLevel.info)), isFalse);
    });

    test("drops every message when the minimum level turns the logs off", () {
      final filter = DefaultLogFilter(minLevel: LogsLevel.off);

      expect(filter.shouldLog(_event(LogsLevel.fatal)), isFalse);
    });

    test("follows the minimum level it has been set to", () {
      final filter = DefaultLogFilter(minLevel: LogsLevel.error);

      filter.minLevel = LogsLevel.debug;

      expect(filter.shouldLog(_event(LogsLevel.debug)), isTrue);
    });

    test("keeps every message when it has no level to filter on", () {
      final filter = DefaultLogFilter()..level = null;

      expect(filter.shouldLog(_event(LogsLevel.trace)), isTrue);
    });
  });
}
