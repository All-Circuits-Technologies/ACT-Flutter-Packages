// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("NumBoundaries", () {
    test("keeps the two boundaries it is given", () {
      final boundaries = NumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.min, 1);
      expect(boundaries.max, 10);
    });

    test("tests both boundaries", () {
      final boundaries = NumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.isInBoundaries(5), isTrue);
      expect(boundaries.isInBoundaries(0), isFalse);
      expect(boundaries.isInBoundaries(11), isFalse);
    });

    test("works on the decimal numbers as well", () {
      final boundaries = NumBoundaries<double>(min: 1.5, max: 2.5);

      expect(boundaries.isInBoundaries(2), isTrue);
      expect(boundaries.isInBoundaries(1.4), isFalse);
    });
  });

  group("NumBoundaries.copyWith", () {
    test("keeps the boundaries which are not given", () {
      final boundaries = NumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(), boundaries);
    });

    test("replaces the boundary it is given", () {
      final boundaries = NumBoundaries<int>(min: 1, max: 10);

      expect(boundaries.copyWith(min: 2), NumBoundaries<int>(min: 2, max: 10));
    });
  });
}
