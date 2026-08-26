// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("StringInterval", () {
    test("derives the end index from the start index and the length", () {
      final interval = StringInterval(key: "ber", startIdx: 3, length: 3);

      expect(interval.endIdx, 5);
    });

    test("covers a single character when the length is one", () {
      final interval = StringInterval(key: "a", startIdx: 2, length: 1);

      expect(interval.startIdx, 2);
      expect(interval.endIdx, 2);
    });

    test("keeps the end index it is given", () {
      final interval = StringInterval.withEndIdx(key: null, startIdx: 0, endIdx: 2);

      expect(interval.endIdx, 2);
    });

    test("accepts an interval without any key", () {
      expect(StringInterval.withEndIdx(key: null, startIdx: 0, endIdx: 1).key, isNull);
    });
  });

  group("StringInterval.placeInRelationToInterval", () {
    test("returns zero for an index inside the interval", () {
      final interval = StringInterval(key: "ber", startIdx: 3, length: 3);

      expect(interval.placeInRelationToInterval(3), 0);
      expect(interval.placeInRelationToInterval(4), 0);
      expect(interval.placeInRelationToInterval(5), 0);
    });

    test("returns a negative value for an index before the interval", () {
      final interval = StringInterval(key: "ber", startIdx: 3, length: 3);

      expect(interval.placeInRelationToInterval(2), -1);
    });

    test("returns a positive value for an index after the interval", () {
      final interval = StringInterval(key: "ber", startIdx: 3, length: 3);

      expect(interval.placeInRelationToInterval(6), 1);
    });
  });

  group("StringInterval.getIntervalString", () {
    test("returns the characters the interval covers", () {
      final interval = StringInterval(key: "ber", startIdx: 3, length: 3);

      expect(interval.getIntervalString("Cumbersome"), "ber");
    });

    test("returns a single character for an interval of one", () {
      final interval = StringInterval(key: "C", startIdx: 0, length: 1);

      expect(interval.getIntervalString("Cumbersome"), "C");
    });
  });
}
