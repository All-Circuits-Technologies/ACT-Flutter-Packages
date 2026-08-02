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
}
