// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("NullableNumBoundaries", () {
    test("accepts to have no boundary at all", () {
      final boundaries = NullableNumBoundaries<int>();

      expect(boundaries.isInBoundaries(-100), isTrue);
      expect(boundaries.isInBoundaries(100), isTrue);
    });

    test("only tests the boundary it has", () {
      final boundaries = NullableNumBoundaries<int>(min: 1);

      expect(boundaries.isInBoundaries(100), isTrue);
      expect(boundaries.isInBoundaries(0), isFalse);
    });
  });

  group("NullableNumBoundaries.copyWith", () {
    test("keeps the boundaries which are not given", () {
      final boundaries = NullableNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(), boundaries);
    });

    test("replaces the boundary it is given", () {
      final boundaries = NullableNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(max: 20), NullableNumBoundaries<int>(min: 1, max: 20));
    });

    test("drops a boundary when it is forced without a new one", () {
      final boundaries = NullableNumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(forceMinValue: true).min, isNull);
      expect(boundaries.copyWith(forceMaxValue: true).max, isNull);
    });
  });
}
