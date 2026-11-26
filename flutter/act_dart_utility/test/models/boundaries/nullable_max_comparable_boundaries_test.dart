// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("NullableMaxComparableBoundaries", () {
    test("always has a minimum and may have no maximum", () {
      final boundaries = NullableMaxComparableBoundaries<String>(min: "b");

      expect(boundaries.min, "b");
      expect(boundaries.max, isNull);
    });

    test("only tests the minimum when there is no maximum", () {
      final boundaries = NullableMaxComparableBoundaries<String>(min: "b");

      expect(boundaries.isInBoundaries("z"), isTrue);
      expect(boundaries.isInBoundaries("a"), isFalse);
    });

    test("tests both boundaries when it has a maximum", () {
      final boundaries = NullableMaxComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.isInBoundaries("c"), isTrue);
      expect(boundaries.isInBoundaries("e"), isFalse);
    });
  });

  group("NullableMaxComparableBoundaries.copyWith", () {
    test("keeps the boundaries which are not given", () {
      final boundaries = NullableMaxComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(), boundaries);
    });

    test("drops the maximum when it is forced without a new one", () {
      final boundaries = NullableMaxComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(forceMaxValue: true).max, isNull);
    });

    test("replaces the minimum it is given", () {
      final boundaries = NullableMaxComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(min: "c").min, "c");
    });
  });
}
