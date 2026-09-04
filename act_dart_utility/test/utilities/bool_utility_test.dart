// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BoolUtility.parseFromInt", () {
    test("returns false for the integer value of false", () {
      expect(BoolUtility.parseFromInt(BoolUtility.falseIntValue), isFalse);
    });

    test("returns true for the integer value of true", () {
      expect(BoolUtility.parseFromInt(BoolUtility.trueIntValue), isTrue);
    });

    test("returns true for any other integer", () {
      expect(BoolUtility.parseFromInt(42), isTrue);
      expect(BoolUtility.parseFromInt(-1), isTrue);
    });
  });

  group("BoolUtility.toInt", () {
    test("returns the integer value of true for true", () {
      expect(BoolUtility.toInt(true), BoolUtility.trueIntValue);
    });

    test("returns the integer value of false for false", () {
      expect(BoolUtility.toInt(false), BoolUtility.falseIntValue);
    });

    test("round trips with parseFromInt", () {
      expect(BoolUtility.parseFromInt(BoolUtility.toInt(true)), isTrue);
      expect(BoolUtility.parseFromInt(BoolUtility.toInt(false)), isFalse);
    });
  });

  group("BoolUtility.parse", () {
    test("accepts the words true and false", () {
      expect(BoolUtility.parse("true"), isTrue);
      expect(BoolUtility.parse("false"), isFalse);
    });

    test("accepts the digits one and zero", () {
      expect(BoolUtility.parse("1"), isTrue);
      expect(BoolUtility.parse("0"), isFalse);
    });

    test("ignores the case of the value", () {
      expect(BoolUtility.parse("TRUE"), isTrue);
      expect(BoolUtility.parse("False"), isFalse);
    });

    test("reads back what bool.toString produced", () {
      expect(BoolUtility.parse(true.toString()), isTrue);
      expect(BoolUtility.parse(false.toString()), isFalse);
    });

    test("throws on a value which describes no boolean", () {
      expect(() => BoolUtility.parse("yes"), throwsFormatException);
    });

    test("throws on an empty value", () {
      expect(() => BoolUtility.parse(""), throwsFormatException);
    });

    test("throws on a value surrounded by spaces", () {
      expect(() => BoolUtility.parse(" true "), throwsFormatException);
    });
  });

  group("BoolUtility.tryParse", () {
    test("returns the boolean of a valid value", () {
      expect(BoolUtility.tryParse("true"), isTrue);
      expect(BoolUtility.tryParse("0"), isFalse);
    });

    test("returns null on a value which describes no boolean", () {
      expect(BoolUtility.tryParse("yes"), isNull);
    });

    test("warns through the logger when the value describes no boolean", () {
      final logger = FakeLogger();

      BoolUtility.tryParse("yes", logger: logger);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("logs nothing when the value is valid", () {
      final logger = FakeLogger();

      BoolUtility.tryParse("true", logger: logger);

      expect(logger.records, isEmpty);
    });
  });
}
