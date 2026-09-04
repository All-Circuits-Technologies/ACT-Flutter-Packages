// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActMapExtension.copy", () {
    test("returns a map with the same entries", () {
      expect({"a": 1}.copy(), {"a": 1});
    });

    test("returns a map which is not the given one", () {
      final map = {"a": 1};

      map.copy()["b"] = 2;

      expect(map, {"a": 1});
    });
  });

  group("ActMapExtension.copyAndMerge", () {
    test("merges the entries of the two maps", () {
      expect({"a": 1}.copyAndMerge({"b": 2}), {"a": 1, "b": 2});
    });

    test("returns a copy when there is nothing to merge", () {
      expect({"a": 1}.copyAndMerge(null), {"a": 1});
    });
  });

  group("ActMapExtension.copyAndMergeOrNull", () {
    test("merges the entries of the two maps", () {
      expect({"a": 1}.copyAndMergeOrNull({"b": 2}), {"a": 1, "b": 2});
    });

    test("returns null when there is nothing to merge", () {
      expect({"a": 1}.copyAndMergeOrNull(null), isNull);
      expect({"a": 1}.copyAndMergeOrNull({}), isNull);
    });
  });
}
