// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("NullableMinComparableBoundaries", () {
    test("always has a maximum and may have no minimum", () {
      final boundaries = NullableMinComparableBoundaries<String>(max: "d");

      expect(boundaries.min, isNull);
      expect(boundaries.max, "d");
    });

    test("only tests the maximum when there is no minimum", () {
      final boundaries = NullableMinComparableBoundaries<String>(max: "d");

      expect(boundaries.isInBoundaries("a"), isTrue);
      expect(boundaries.isInBoundaries("e"), isFalse);
    });

    test("tests both boundaries when it has a minimum", () {
      final boundaries = NullableMinComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.isInBoundaries("a"), isFalse);
      expect(boundaries.isInBoundaries("c"), isTrue);
    });
  });

  group("NullableMinComparableBoundaries.copyWith", () {
    test("keeps the boundaries which are not given", () {
      final boundaries = NullableMinComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(), boundaries);
    });

    test("drops the minimum when it is forced without a new one", () {
      final boundaries = NullableMinComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(forceMinValue: true).min, isNull);
    });

    test("replaces the maximum it is given", () {
      final boundaries = NullableMinComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(max: "e").max, "e");
    });
  });
}
