// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// A number of milliseconds no DateTime can be built from.
const _outOfRangeMilliseconds = 10000000000000000;

/// A number of seconds no DateTime can be built from.
const _outOfRangeSeconds = 9000000000000;

void main() {
  group("DateTimeUtility.epoch", () {
    test("is the first moment of 1970 in UTC", () {
      expect(DateTimeUtility.epoch, DateTime.utc(1970));
      expect(DateTimeUtility.epoch.millisecondsSinceEpoch, 0);
      expect(DateTimeUtility.epoch.isUtc, isTrue);
    });
  });

  group("DateTimeUtility.fromMillisecondsSinceEpoch", () {
    test("builds the date of the given moment", () {
      expect(
        DateTimeUtility.fromMillisecondsSinceEpoch(1000, isUtc: true),
        DateTime.utc(1970, 1, 1, 0, 0, 1),
      );
    });

    test("builds a local date by default", () {
      expect(DateTimeUtility.fromMillisecondsSinceEpoch(0)!.isUtc, isFalse);
    });

    test("returns null when the value is out of the range of a date", () {
      expect(DateTimeUtility.fromMillisecondsSinceEpoch(_outOfRangeMilliseconds), isNull);
    });

    test("warns through the logger when the value is out of range", () {
      final logger = FakeLogger();

      DateTimeUtility.fromMillisecondsSinceEpoch(_outOfRangeMilliseconds, logger: logger);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("DateTimeUtility.fromMillisecondsSinceEpochUtc", () {
    test("builds a date in UTC", () {
      expect(DateTimeUtility.fromMillisecondsSinceEpochUtc(0), DateTimeUtility.epoch);
    });
  });

  group("DateTimeUtility.fromSecondsSinceEpoch", () {
    test("builds the date of the given moment", () {
      expect(
        DateTimeUtility.fromSecondsSinceEpoch(60, isUtc: true),
        DateTime.utc(1970, 1, 1, 0, 1),
      );
    });

    test("builds a local date by default", () {
      expect(DateTimeUtility.fromSecondsSinceEpoch(0)!.isUtc, isFalse);
    });

    test("returns null when the value is out of the range of a date", () {
      expect(DateTimeUtility.fromSecondsSinceEpoch(_outOfRangeSeconds), isNull);
    });
  });

  group("DateTimeUtility.fromSecondsSinceEpochUtc", () {
    test("builds a date in UTC", () {
      expect(DateTimeUtility.fromSecondsSinceEpochUtc(0), DateTimeUtility.epoch);
    });
  });

  group("DateTimeUtility.tryParseUtc", () {
    test("parses a formatted date and marks it as UTC", () {
      final date = DateTimeUtility.tryParseUtc("2026-08-02T10:20:30");

      expect(date, DateTime.utc(2026, 8, 2, 10, 20, 30));
      expect(date!.isUtc, isTrue);
    });

    test("keeps the fields of a date which already carries a zone", () {
      final date = DateTimeUtility.tryParseUtc("2026-08-02T10:20:30Z");

      expect(date, DateTime.utc(2026, 8, 2, 10, 20, 30));
    });

    test("returns null when the value is not a date", () {
      expect(DateTimeUtility.tryParseUtc("not a date"), isNull);
    });
  });

  group("DateTimeUtility.getLastMomentOfADate", () {
    test("returns the last microsecond of the day of the given date", () {
      expect(
        DateTimeUtility.getLastMomentOfADate(DateTime(2026, 8, 2, 10, 20)),
        DateTime(2026, 8, 2, 23, 59, 59, 999, 999),
      );
    });

    test("keeps the day even when the given date is already its last moment", () {
      final lastMoment = DateTimeUtility.getLastMomentOfADate(DateTime(2026, 8, 2));

      expect(DateTimeUtility.getLastMomentOfADate(lastMoment), lastMoment);
    });
  });

  group("DateTimeUtility.getCurrentAge", () {
    test("returns the number of full years since the birth date", () {
      final birthDate = DateTime.now().toUtc().subtract(const Duration(days: 365 * 30 + 8));

      expect(DateTimeUtility.getCurrentAge(birthDate), 30);
    });

    test("returns zero for a birth date in the future", () {
      final birthDate = DateTime.now().toUtc().add(const Duration(days: 365));

      expect(DateTimeUtility.getCurrentAge(birthDate), 0);
    });

    test("returns zero for a birth date of today", () {
      expect(DateTimeUtility.getCurrentAge(DateTime.now().toUtc()), 0);
    });

    test("does not count a year which is not complete yet", () {
      final birthDate = DateTime.now().toUtc().subtract(const Duration(days: 300));

      expect(DateTimeUtility.getCurrentAge(birthDate), 0);
    });
  });

  group("DateTimeUtility.addMonths", () {
    test("adds the months and keeps the time of day", () {
      expect(
        DateTimeUtility.addMonths(DateTime(2026, 1, 15, 10, 20, 30), 7),
        DateTime(2026, 8, 15, 10, 20, 30),
      );
    });

    test("clamps the day to the length of the arrival month", () {
      expect(DateTimeUtility.addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(DateTimeUtility.addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      expect(DateTimeUtility.addMonths(DateTime(2026, 3, 31), 1), DateTime(2026, 4, 30));
    });

    test("crosses the years in both directions", () {
      expect(DateTimeUtility.addMonths(DateTime(2026, 8, 25), 5), DateTime(2027, 1, 25));
      expect(DateTimeUtility.addMonths(DateTime(2026, 8, 25), 17), DateTime(2028, 1, 25));
      expect(DateTimeUtility.addMonths(DateTime(2026, 1, 25), -1), DateTime(2025, 12, 25));
      expect(DateTimeUtility.addMonths(DateTime(2026, 1, 25), -13), DateTime(2024, 12, 25));
    });

    test("keeps the time zone of the given date", () {
      expect(DateTimeUtility.addMonths(DateTime.utc(2026, 1, 15), 1).isUtc, isTrue);
      expect(DateTimeUtility.addMonths(DateTime(2026, 1, 15), 1).isUtc, isFalse);
    });

    test("returns the given date when no month is added", () {
      final date = DateTime(2026, 8, 25, 10, 20, 30);

      expect(DateTimeUtility.addMonths(date, 0), date);
    });
  });

  group("DateTimeUtility.wholeMonthsBetween", () {
    test("returns zero for two equal date times", () {
      final date = DateTime(2026, 8, 25, 10, 20, 30);

      expect(DateTimeUtility.wholeMonthsBetween(from: date, to: date), 0);
    });

    test("counts the whole months of the interval", () {
      expect(
        DateTimeUtility.wholeMonthsBetween(from: DateTime(2026, 1, 20), to: DateTime(2026, 8, 20)),
        7,
      );
      expect(
        DateTimeUtility.wholeMonthsBetween(from: DateTime(2025, 12, 31), to: DateTime(2026, 8, 25)),
        7,
      );
    });

    test("does not count the month which is not complete yet", () {
      expect(
        DateTimeUtility.wholeMonthsBetween(from: DateTime(2026, 1, 20), to: DateTime(2026, 8, 19)),
        6,
      );
      expect(
        DateTimeUtility.wholeMonthsBetween(from: DateTime(2026, 1, 2), to: DateTime(2026, 1, 30)),
        0,
      );
    });

    test("counts the time of day of the interval bounds", () {
      expect(
        DateTimeUtility.wholeMonthsBetween(
          from: DateTime(2026, 1, 15, 18),
          to: DateTime(2026, 2, 15, 9),
        ),
        0,
      );
      expect(
        DateTimeUtility.wholeMonthsBetween(
          from: DateTime(2026, 1, 15, 18),
          to: DateTime(2026, 2, 15, 18),
        ),
        1,
      );
    });

    test("stands the last day of the month in for a day which does not exist", () {
      expect(
        DateTimeUtility.wholeMonthsBetween(from: DateTime(2026, 1, 31), to: DateTime(2026, 2, 28)),
        1,
      );
      expect(
        DateTimeUtility.wholeMonthsBetween(from: DateTime(2026, 1, 31), to: DateTime(2026, 2, 27)),
        0,
      );
    });

    test("returns the opposite count when the bounds are swapped", () {
      final from = DateTime(2026, 1, 20);
      final to = DateTime(2026, 8, 19);

      expect(DateTimeUtility.wholeMonthsBetween(from: to, to: from), -6);
      expect(
        DateTimeUtility.wholeMonthsBetween(from: to, to: from),
        -DateTimeUtility.wholeMonthsBetween(from: from, to: to),
      );
    });

    test("compares the bounds in the time zone of the first one", () {
      final from = DateTime.utc(2026, 1, 20, 12);

      expect(
        DateTimeUtility.wholeMonthsBetween(from: from, to: from.add(const Duration(days: 213))),
        7,
      );
      expect(
        DateTimeUtility.wholeMonthsBetween(
          from: from,
          to: from.toLocal().add(const Duration(days: 213)),
        ),
        7,
      );
    });
  });
}
