// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("StringListUtility.trim", () {
    test("removes the empty string at the beginning and at the end", () {
      expect(StringListUtility.trim(["", "a", "b", "", "c", ""]), ["a", "b", "", "c"]);
    });

    test("keeps the empty strings which are in the middle", () {
      expect(StringListUtility.trim(["a", "", "", "b"]), ["a", "", "", "b"]);
    });

    test("only removes one empty string at each end", () {
      expect(StringListUtility.trim(["", "", "a", "", ""]), ["", "a", ""]);
    });

    test("leaves a list which starts and ends with a value untouched", () {
      expect(StringListUtility.trim(["a", "b"]), ["a", "b"]);
    });

    test("returns an empty list for an empty one", () {
      expect(StringListUtility.trim([]), isEmpty);
    });

    test("empties a list which only holds an empty string", () {
      expect(StringListUtility.trim([""]), isEmpty);
    });

    test("leaves the given list untouched", () {
      final list = ["", "a", ""];

      StringListUtility.trim(list);

      expect(list, ["", "a", ""]);
    });

    test("returns a list which cannot grow when it is asked to and there is nothing to trim", () {
      final trimmed = StringListUtility.trim([], growable: false);

      expect(() => trimmed.add("a"), throwsUnsupportedError);
    });

    test("returns a growable list as soon as it has something to trim", () {
      // The growable argument is only honoured on the empty list: the trimmed list comes from
      // sublist, which always returns a growable list.
      final trimmed = StringListUtility.trim(["", "a"], growable: false);

      expect(() => trimmed.add("b"), returnsNormally);
    });
  });
}
