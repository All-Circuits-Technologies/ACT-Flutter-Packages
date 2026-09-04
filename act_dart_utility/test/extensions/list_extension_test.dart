// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_dart_utility/act_dart_utility_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActListExtension copies", () {
    test("copies the list", () {
      final list = [1, 2];

      expect(list.copy(), list);
      expect(list.copy(), isNot(same(list)));
    });

    test("copies the list without a value", () {
      expect([1, 2, 1].copyWithoutValue(1), [2]);
    });

    test("copies the list without several values", () {
      expect([1, 2, 3].copyWithoutValues([1, 3]), [2]);
    });
  });

  group("ActListExtension interleaves", () {
    test("inserts the value between the elements", () {
      expect([1, 2].interleave(0), [1, 0, 2]);
    });

    test("adds the value at the ends when it is asked to", () {
      expect([1, 2].interleave(0, addLeft: true, addRight: true), [0, 1, 0, 2, 0]);
    });

    test("builds a new interleave for every insertion", () {
      var built = 0;

      expect([1, 2, 3].interleaveWithBuilder(() => --built), [1, -1, 2, -2, 3]);
    });
  });

  group("ActListExtension sublists", () {
    test("returns the elements between the two indexes", () {
      expect([1, 2, 3, 4].safeSublist(1, 3), [2, 3]);
    });

    test("returns an empty list when the start overflows the list", () {
      expect([1, 2].safeSublist(5), isEmpty);
    });

    test("returns the asked number of elements from the start", () {
      expect([1, 2, 3, 4].safeSublistFromLength(1, 2), [2, 3]);
    });
  });

  group("ActListExtension.distinct", () {
    test("removes the duplicated elements", () {
      expect([3, 1, 3].distinct(), [3, 1]);
    });

    test("uses the given unique element", () {
      expect(
        ["a1", "b1", "a2"].distinct<String>(getUniqueElem: (item) => item[0]),
        ["a1", "b1"],
      );
    });
  });

  group("ActListExtension.moveElement", () {
    test("moves the element in the list itself", () {
      final list = ["a", "b", "c"]..moveElement(0, 2);

      expect(list, ["b", "a", "c"]);
    });
  });

  group("ActListExtension.appendOrReplace", () {
    test("appends the list when no start is given", () {
      expect([1, 2].appendOrReplace([3]), [1, 2, 3]);
    });

    test("replaces the elements from the start", () {
      expect([1, 2, 3].appendOrReplace([8], 1), [2, 3, 8]);
    });
  });

  group("ActListExtension indexes", () {
    test("returns the index of the first matching element", () {
      expect([1, 2].indexWhereOrNull((element) => element.isEven), 1);
    });

    test("returns null when no element matches", () {
      expect([1, 3].indexWhereOrNull((element) => element.isEven), isNull);
    });

    test("returns the not found index when no element matches", () {
      expect(
        [1, 3].indexWhereOrDefault((element) => element.isEven),
        ListUtility.defaultIndexOfValueNotFound,
      );
    });

    test("returns the given default value when no element matches", () {
      expect([1, 3].indexWhereOrDefault((element) => element.isEven, defaultValue: 42), 42);
    });

    test("returns every index where the test passes", () {
      expect([1, 2, 3, 4].indexesWhere((element) => element.isEven), [1, 3]);
    });

    test("returns the indexes from the end of the list", () {
      expect([1, 2, 3, 4].lastIndexesWhere((element) => element.isEven), [3, 1]);
    });
  });
}
