// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("CustomComparableBoundaries", () {
    test("keeps the boundaries it is given", () {
      final boundaries = CustomComparableBoundaries<int, int, int, num>(min: 1, max: 10);

      expect(boundaries.min, 1);
      expect(boundaries.max, 10);
    });

    test("accepts boundaries which are equal", () {
      expect(
        () => CustomComparableBoundaries<int, int, int, num>(min: 5, max: 5),
        returnsNormally,
      );
    });

    test("refuses a minimum which is greater than the maximum", () {
      expect(
        () => CustomComparableBoundaries<int, int, int, num>(min: 10, max: 1),
        throwsAssertionError,
      );
    });

    test("accepts any maximum when there is no minimum", () {
      expect(
        () => CustomComparableBoundaries<int?, int, int, num>(min: null, max: 1),
        returnsNormally,
      );
    });
  });

  group("CustomComparableBoundaries.isInBoundaries", () {
    test("accepts a value between the boundaries", () {
      final boundaries = CustomComparableBoundaries<int, int, int, num>(min: 1, max: 10);

      expect(boundaries.isInBoundaries(5), isTrue);
    });

    test("rejects a value outside of the boundaries", () {
      final boundaries = CustomComparableBoundaries<int, int, int, num>(min: 1, max: 10);

      expect(boundaries.isInBoundaries(0), isFalse);
      expect(boundaries.isInBoundaries(11), isFalse);
    });

    test("accepts a value equal to a boundary by default", () {
      final boundaries = CustomComparableBoundaries<int, int, int, num>(min: 1, max: 10);

      expect(boundaries.isInBoundaries(1), isTrue);
      expect(boundaries.isInBoundaries(10), isTrue);
    });

    test("rejects a value equal to a boundary when the comparison is strict", () {
      final boundaries = CustomComparableBoundaries<int, int, int, num>(min: 1, max: 10);

      expect(boundaries.isInBoundaries(1, strictCompare: true), isFalse);
      expect(boundaries.isInBoundaries(10, strictCompare: true), isFalse);
      expect(boundaries.isInBoundaries(5, strictCompare: true), isTrue);
    });

    test("does not test the minimum when there is none", () {
      final boundaries = CustomComparableBoundaries<int?, int, int, num>(min: null, max: 10);

      expect(boundaries.isInBoundaries(-100), isTrue);
      expect(boundaries.isInBoundaries(11), isFalse);
    });

    test("does not test the maximum when there is none", () {
      final boundaries = CustomComparableBoundaries<int, int?, int, num>(min: 1, max: null);

      expect(boundaries.isInBoundaries(100), isTrue);
      expect(boundaries.isInBoundaries(0), isFalse);
    });

    test("accepts everything when there is no boundary at all", () {
      final boundaries = CustomComparableBoundaries<int?, int?, int, num>(min: null, max: null);

      expect(boundaries.isInBoundaries(-100), isTrue);
      expect(boundaries.isInBoundaries(100), isTrue);
    });

    test("compares the values which are not numbers", () {
      final boundaries = CustomComparableBoundaries<String, String, String, String>(
        min: "b",
        max: "d",
      );

      expect(boundaries.isInBoundaries("c"), isTrue);
      expect(boundaries.isInBoundaries("a"), isFalse);
      expect(boundaries.isInBoundaries("e"), isFalse);
    });
  });

  group("CustomComparableBoundaries equality", () {
    test("considers two boundaries with the same values as equal", () {
      expect(
        CustomComparableBoundaries<int, int, int, num>(min: 1, max: 10),
        CustomComparableBoundaries<int, int, int, num>(min: 1, max: 10),
      );
    });

    test("considers two boundaries with different values as different", () {
      expect(
        CustomComparableBoundaries<int, int, int, num>(min: 1, max: 10),
        isNot(CustomComparableBoundaries<int, int, int, num>(min: 1, max: 11)),
      );
    });
  });
}
