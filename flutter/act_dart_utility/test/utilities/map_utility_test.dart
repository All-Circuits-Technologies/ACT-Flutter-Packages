// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("MapUtility.copy", () {
    test("returns a map with the same entries", () {
      expect(MapUtility.copy({"a": 1, "b": 2}), {"a": 1, "b": 2});
    });

    test("returns a map which is not the given one", () {
      final map = {"a": 1};

      final copy = MapUtility.copy(map)..["b"] = 2;

      expect(map, {"a": 1});
      expect(copy, {"a": 1, "b": 2});
    });

    test("returns an empty map for an empty one", () {
      expect(MapUtility.copy(<String, int>{}), isEmpty);
    });
  });

  group("MapUtility.copyAndMerge", () {
    test("adds the entries which are not in the base map", () {
      expect(MapUtility.copyAndMerge({"a": 1}, {"b": 2}), {"a": 1, "b": 2});
    });

    test("overrides the entries which are in both maps", () {
      expect(MapUtility.copyAndMerge({"a": 1}, {"a": 2}), {"a": 2});
    });

    test("returns a copy of the base map when there is nothing to merge", () {
      expect(MapUtility.copyAndMerge({"a": 1}, null), {"a": 1});
    });

    test("leaves the base map untouched", () {
      final map = {"a": 1};

      MapUtility.copyAndMerge(map, {"b": 2});

      expect(map, {"a": 1});
    });
  });

  group("MapUtility.copyAndMergeOrNull", () {
    test("merges the entries as the merge does", () {
      expect(MapUtility.copyAndMergeOrNull({"a": 1}, {"a": 2, "b": 3}), {"a": 2, "b": 3});
    });

    test("returns null when there is nothing to merge", () {
      expect(MapUtility.copyAndMergeOrNull({"a": 1}, null), isNull);
    });

    test("returns null when the map to merge is empty", () {
      expect(MapUtility.copyAndMergeOrNull({"a": 1}, {}), isNull);
    });
  });
}
