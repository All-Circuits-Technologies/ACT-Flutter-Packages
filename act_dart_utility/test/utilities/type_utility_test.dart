// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("TypeUtility.testValueType", () {
    test("returns true when the value has the given primary type", () {
      expect(TypeUtility.testValueType(bool, true), isTrue);
      expect(TypeUtility.testValueType(int, 42), isTrue);
      expect(TypeUtility.testValueType(double, 4.2), isTrue);
      expect(TypeUtility.testValueType(String, "a value"), isTrue);
    });

    test("returns false when the value has another type", () {
      expect(TypeUtility.testValueType(int, "42"), isFalse);
      expect(TypeUtility.testValueType(String, 42), isFalse);
    });

    test("tells an integer and a double apart", () {
      expect(TypeUtility.testValueType(double, 42), isFalse);
      expect(TypeUtility.testValueType(int, 4.2), isFalse);
    });

    test("returns false for a null value", () {
      expect(TypeUtility.testValueType(String, null), isFalse);
    });

    test("returns false for a type which is not a primary one", () {
      expect(TypeUtility.testValueType(Duration, const Duration(seconds: 1)), isFalse);
    });
  });
}
