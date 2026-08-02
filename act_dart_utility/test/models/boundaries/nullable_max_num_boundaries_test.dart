// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("NullableMaxNumBoundaries", () {
    test("always has a minimum and may have no maximum", () {
      final boundaries = NullableMaxNumBoundaries<int>(min: 1);

      expect(boundaries.min, 1);
      expect(boundaries.max, isNull);
    });

    test("only tests the minimum when there is no maximum", () {
      final boundaries = NullableMaxNumBoundaries<int>(min: 1);

      expect(boundaries.isInBoundaries(1000), isTrue);
      expect(boundaries.isInBoundaries(0), isFalse);
    });

    test("tests both boundaries when it has a maximum", () {
      final boundaries = NullableMaxNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.isInBoundaries(5), isTrue);
      expect(boundaries.isInBoundaries(11), isFalse);
    });
  });

  group("NullableMaxNumBoundaries.copyWith", () {
    test("keeps the boundaries which are not given", () {
      final boundaries = NullableMaxNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(), boundaries);
    });

    test("drops the maximum when it is forced without a new one", () {
      final boundaries = NullableMaxNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(forceMaxValue: true).max, isNull);
    });

    test("replaces the minimum it is given", () {
      final boundaries = NullableMaxNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(min: 2).min, 2);
    });
  });
}
