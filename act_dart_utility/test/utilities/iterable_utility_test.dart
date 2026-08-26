// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("IterableUtility.firstWhereOrNull", () {
    test("returns the first matching element", () {
      expect(IterableUtility.firstWhereOrNull([1, 2, 3, 4], (element) => element.isEven), 2);
    });

    test("returns null when no element matches", () {
      expect(IterableUtility.firstWhereOrNull([1, 3], (element) => element.isEven), isNull);
    });

    test("returns null on an empty collection", () {
      expect(IterableUtility.firstWhereOrNull(<int>[], (element) => true), isNull);
    });

    test("returns null when the collection is null", () {
      expect(IterableUtility.firstWhereOrNull(null, (int element) => true), isNull);
    });
  });

  group("IterableUtility.copyWithoutValue", () {
    test("removes every occurrence of the value", () {
      expect(IterableUtility.copyWithoutValue([1, 2, 1, 3], 1), [2, 3]);
    });

    test("returns the same elements when the value is not there", () {
      expect(IterableUtility.copyWithoutValue([1, 2], 3), [1, 2]);
    });

    test("removes the null elements when the value is null", () {
      expect(IterableUtility.copyWithoutValue([1, null, 2], null), [1, 2]);
    });
  });

  group("IterableUtility.copyWithoutValues", () {
    test("removes every occurrence of every value", () {
      expect(IterableUtility.copyWithoutValues([1, 2, 3, 1], [1, 3]), [2]);
    });

    test("returns the same elements when there is nothing to remove", () {
      expect(IterableUtility.copyWithoutValues([1, 2], <int>[]), [1, 2]);
    });
  });

  group("IterableUtility.testIfAtLeastOneIsInCollection", () {
    test("returns true when one element is in the collection", () {
      expect(IterableUtility.testIfAtLeastOneIsInCollection([3, 1], [1, 2]), isTrue);
    });

    test("returns false when no element is in the collection", () {
      expect(IterableUtility.testIfAtLeastOneIsInCollection([3, 4], [1, 2]), isFalse);
    });

    test("returns false when there is no element to look for", () {
      expect(IterableUtility.testIfAtLeastOneIsInCollection(<int>[], [1, 2]), isFalse);
    });
  });

  group("IterableUtility.testIfListIsInCollection", () {
    test("returns true when every element is in the collection", () {
      expect(IterableUtility.testIfListIsInCollection([1, 2], [1, 2, 3]), isTrue);
    });

    test("returns false when one element is missing", () {
      expect(IterableUtility.testIfListIsInCollection([1, 4], [1, 2, 3]), isFalse);
    });

    test("returns true when there is no element to look for", () {
      expect(IterableUtility.testIfListIsInCollection(<int>[], [1, 2]), isTrue);
    });
  });
}
