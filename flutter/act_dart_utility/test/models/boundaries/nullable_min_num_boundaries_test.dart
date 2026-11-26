// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("NullableMinNumBoundaries", () {
    test("always has a maximum and may have no minimum", () {
      final boundaries = NullableMinNumBoundaries<int>(max: 10);

      expect(boundaries.min, isNull);
      expect(boundaries.max, 10);
    });

    test("only tests the maximum when there is no minimum", () {
      final boundaries = NullableMinNumBoundaries<int>(max: 10);

      expect(boundaries.isInBoundaries(-100), isTrue);
      expect(boundaries.isInBoundaries(11), isFalse);
    });

    test("tests both boundaries when it has a minimum", () {
      final boundaries = NullableMinNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.isInBoundaries(0), isFalse);
      expect(boundaries.isInBoundaries(5), isTrue);
    });
  });

  group("NullableMinNumBoundaries.copyWith", () {
    test("keeps the boundaries which are not given", () {
      final boundaries = NullableMinNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(), boundaries);
    });

    test("drops the minimum when it is forced without a new one", () {
      final boundaries = NullableMinNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(forceMinValue: true).min, isNull);
    });

    test("replaces the maximum it is given", () {
      final boundaries = NullableMinNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(max: 20).max, 20);
    });
  });
}
