// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("DurationUtility.formatMinSec", () {
    test("writes the minutes and the seconds", () {
      expect(DurationUtility.formatMinSec(const Duration(minutes: 3, seconds: 7)), "3:07");
    });

    test("pads the seconds to two digits", () {
      expect(DurationUtility.formatMinSec(const Duration(seconds: 5)), "0:05");
    });

    test("counts the hours as minutes", () {
      expect(DurationUtility.formatMinSec(const Duration(hours: 1, seconds: 30)), "60:30");
    });

    test("drops what is below the second", () {
      expect(DurationUtility.formatMinSec(const Duration(milliseconds: 1500)), "0:01");
    });

    test("returns null when there is no duration", () {
      expect(DurationUtility.formatMinSec(null), isNull);
    });
  });

  group("DurationUtility.parseFromSeconds", () {
    test("builds the duration of the given seconds", () {
      expect(DurationUtility.parseFromSeconds(90), const Duration(seconds: 90));
    });

    test("builds an empty duration for zero", () {
      expect(DurationUtility.parseFromSeconds(0), Duration.zero);
    });

    test("returns null for a negative number of seconds", () {
      expect(DurationUtility.parseFromSeconds(-1), isNull);
    });
  });

  group("DurationUtility.parseFromMilliseconds", () {
    test("builds the duration of the given milliseconds", () {
      expect(DurationUtility.parseFromMilliseconds(1500), const Duration(milliseconds: 1500));
    });

    test("returns null for a negative number of milliseconds", () {
      expect(DurationUtility.parseFromMilliseconds(-1), isNull);
    });
  });

  group("DurationUtility.parseFromTimeZoneOffset", () {
    test("reads an offset written with a colon", () {
      expect(
        DurationUtility.parseFromTimeZoneOffset("+02:30"),
        const Duration(hours: 2, minutes: 30),
      );
    });

    test("reads an offset written without any colon", () {
      expect(
        DurationUtility.parseFromTimeZoneOffset("+0230"),
        const Duration(hours: 2, minutes: 30),
      );
    });

    test("reads an offset made of hours alone", () {
      expect(DurationUtility.parseFromTimeZoneOffset("+02"), const Duration(hours: 2));
    });

    test("applies the sign to the hours and to the minutes", () {
      expect(
        DurationUtility.parseFromTimeZoneOffset("-02:30"),
        const Duration(hours: -2, minutes: -30),
      );
    });

    test("reads an offset without any sign as a positive one", () {
      expect(DurationUtility.parseFromTimeZoneOffset("02:30"), const Duration(hours: 2, minutes: 30));
    });

    test("reads the UTC marker as an empty offset", () {
      expect(DurationUtility.parseFromTimeZoneOffset("Z"), Duration.zero);
      expect(DurationUtility.parseFromTimeZoneOffset("z"), Duration.zero);
    });

    test("returns null when the value is no offset at all", () {
      expect(DurationUtility.parseFromTimeZoneOffset("here"), isNull);
    });

    test("returns null for an empty value", () {
      expect(DurationUtility.parseFromTimeZoneOffset(""), isNull);
    });
  });
}
