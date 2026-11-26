// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("NullableComparableBoundaries", () {
    test("accepts to have no boundary at all", () {
      final boundaries = NullableComparableBoundaries<String>();

      expect(boundaries.min, isNull);
      expect(boundaries.max, isNull);
      expect(boundaries.isInBoundaries("a"), isTrue);
    });

    test("only tests the boundary it has", () {
      final boundaries = NullableComparableBoundaries<String>(max: "d");

      expect(boundaries.isInBoundaries("a"), isTrue);
      expect(boundaries.isInBoundaries("e"), isFalse);
    });
  });

  group("NullableComparableBoundaries.copyWith", () {
    test("keeps the boundaries which are not given", () {
      final boundaries = NullableComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(), boundaries);
    });

    test("replaces the boundary it is given", () {
      final boundaries = NullableComparableBoundaries<String>(min: "b", max: "d");

      expect(
        boundaries.copyWith(min: "c"),
        NullableComparableBoundaries<String>(min: "c", max: "d"),
      );
    });

    test("drops the minimum when it is forced without a new one", () {
      final boundaries = NullableComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(forceMinValue: true).min, isNull);
    });

    test("drops the maximum when it is forced without a new one", () {
      final boundaries = NullableComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(forceMaxValue: true).max, isNull);
    });

    test("keeps the new boundary even when the drop is forced", () {
      final boundaries = NullableComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(min: "c", forceMinValue: true).min, "c");
    });
  });
}
