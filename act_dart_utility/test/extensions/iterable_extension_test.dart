// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActIterableExtension.firstWhereOrNull", () {
    test("returns the first matching element", () {
      expect([1, 2, 4].firstWhereOrNull((element) => element.isEven), 2);
    });

    test("returns null when no element matches", () {
      expect([1, 3].firstWhereOrNull((element) => element.isEven), isNull);
    });
  });

  group("ActIterableExtension.copyWithoutValue", () {
    test("removes every occurrence of the value", () {
      expect([1, 2, 1].copyWithoutValue(1), [2]);
    });

    test("leaves the collection untouched", () {
      final list = [1, 2];

      list.copyWithoutValue(1).toList();

      expect(list, [1, 2]);
    });
  });

  group("ActIterableExtension.copyWithoutValues", () {
    test("removes every occurrence of every value", () {
      expect([1, 2, 3].copyWithoutValues([1, 3]), [2]);
    });
  });

  group("ActIterableExtension.testIfAtLeastOneIsInCollection", () {
    test("returns true when one element is in the collection", () {
      expect([1, 2].testIfAtLeastOneIsInCollection([3, 1]), isTrue);
    });

    test("returns false when no element is in the collection", () {
      expect([1, 2].testIfAtLeastOneIsInCollection([3]), isFalse);
    });
  });

  group("ActIterableExtension.testIfListIsInCollection", () {
    test("returns true when every element is in the collection", () {
      expect([1, 2, 3].testIfListIsInCollection([1, 2]), isTrue);
    });

    test("returns false when one element is missing", () {
      expect([1, 2, 3].testIfListIsInCollection([1, 4]), isFalse);
    });
  });
}
