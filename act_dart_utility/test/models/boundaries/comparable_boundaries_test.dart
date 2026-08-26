// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ComparableBoundaries", () {
    test("keeps the two boundaries it is given", () {
      final boundaries = ComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.min, "b");
      expect(boundaries.max, "d");
    });

    test("tests both boundaries", () {
      final boundaries = ComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.isInBoundaries("c"), isTrue);
      expect(boundaries.isInBoundaries("a"), isFalse);
      expect(boundaries.isInBoundaries("e"), isFalse);
    });
  });

  group("ComparableBoundaries.copyWith", () {
    test("keeps the boundaries which are not given", () {
      final boundaries = ComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(), boundaries);
    });

    test("replaces the boundary it is given", () {
      final boundaries = ComparableBoundaries<String>(min: "b", max: "d");

      expect(boundaries.copyWith(max: "e"), ComparableBoundaries<String>(min: "b", max: "e"));
    });
  });
}
