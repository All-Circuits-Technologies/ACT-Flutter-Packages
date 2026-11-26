// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActStringListExtension.trim", () {
    test("removes the empty string at the beginning and at the end", () {
      expect(["", "a", "b", "", "c", ""].trim(), ["a", "b", "", "c"]);
    });

    test("leaves a list which starts and ends with a value untouched", () {
      expect(["a", "b"].trim(), ["a", "b"]);
    });

    test("returns an empty list for an empty one", () {
      expect(<String>[].trim(), isEmpty);
    });
  });
}
