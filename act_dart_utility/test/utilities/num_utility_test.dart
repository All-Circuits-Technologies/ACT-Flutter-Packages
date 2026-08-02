// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeLogger logger;

  setUp(() => logger = FakeLogger());

  group("NumUtility.convertDoubleToInt8", () {
    test("keeps the digits the power of ten makes room for", () {
      expect(NumUtility.convertDoubleToInt8(1.25, 2, logger: logger), 125);
    });

    test("truncates what the power of ten leaves out", () {
      expect(NumUtility.convertDoubleToInt8(1.259, 2, logger: logger), 125);
    });

    test("keeps a negative value negative", () {
      expect(NumUtility.convertDoubleToInt8(-1.25, 2, logger: logger), -125);
    });

    test("returns the truncated value when the power of ten is zero", () {
      expect(NumUtility.convertDoubleToInt8(12.9, 0, logger: logger), 12);
    });

    test("returns null when the result overflows the integer", () {
      expect(NumUtility.convertDoubleToInt8(1.28, 2, logger: logger), isNull);
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("returns null when the value is not finite", () {
      expect(NumUtility.convertDoubleToInt8(double.infinity, 0, logger: logger), isNull);
      expect(NumUtility.convertDoubleToInt8(double.nan, 0, logger: logger), isNull);
    });

    test("returns null when the power of ten makes the value not finite", () {
      expect(NumUtility.convertDoubleToInt8(double.maxFinite, 2, logger: logger), isNull);
    });
  });

  group("NumUtility.convertDoubleToUInt8", () {
    test("accepts a value up to the maximum of an unsigned byte", () {
      expect(NumUtility.convertDoubleToUInt8(25.5, 1, logger: logger), 255);
    });

    test("returns null for a negative value", () {
      expect(NumUtility.convertDoubleToUInt8(-1, 0, logger: logger), isNull);
    });

    test("returns null when the result overflows the byte", () {
      expect(NumUtility.convertDoubleToUInt8(25.6, 1, logger: logger), isNull);
    });
  });

  group("NumUtility.convertDoubleToInt16", () {
    test("accepts a value which fits in the integer", () {
      expect(NumUtility.convertDoubleToInt16(3276.7, 1, logger: logger), 32767);
    });

    test("returns null when the result overflows the integer", () {
      expect(NumUtility.convertDoubleToInt16(3276.8, 1, logger: logger), isNull);
    });
  });

  group("NumUtility.convertDoubleToUInt16", () {
    test("accepts a value up to the maximum of the unsigned integer", () {
      expect(NumUtility.convertDoubleToUInt16(655.35, 2, logger: logger), 65535);
    });

    test("returns null for a negative value", () {
      expect(NumUtility.convertDoubleToUInt16(-1, 0, logger: logger), isNull);
    });
  });

  group("NumUtility.convertDoubleToInt32", () {
    test("accepts a value which fits in the integer", () {
      expect(NumUtility.convertDoubleToInt32(214748364.7, 1, logger: logger), 2147483647);
    });

    test("returns null when the result overflows the integer", () {
      expect(NumUtility.convertDoubleToInt32(214748364.8, 1, logger: logger), isNull);
    });
  });

  group("NumUtility.convertDoubleToUInt32", () {
    test("accepts a value which fits in the unsigned integer", () {
      expect(NumUtility.convertDoubleToUInt32(429496729.5, 1, logger: logger), 4294967295);
    });

    test("returns null for a negative value", () {
      expect(NumUtility.convertDoubleToUInt32(-1, 0, logger: logger), isNull);
    });
  });

  group("NumUtility.convertDoubleToInt64", () {
    test("accepts a value which fits in the integer", () {
      expect(NumUtility.convertDoubleToInt64(1.5, 1, logger: logger), 15);
    });

    test("returns null when the value is outside of the range of the integer", () {
      expect(NumUtility.convertDoubleToInt64(1, 20, logger: logger), isNull);
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });
}
