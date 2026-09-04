// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// A model whose identity is its name, to exercise the methods which take a unique element getter.
class _Item {
  final String name;
  final int version;

  const _Item(this.name, this.version);
}

void main() {
  group("ListUtility.copy", () {
    test("returns a list with the same elements", () {
      expect(ListUtility.copy([1, 2]), [1, 2]);
    });

    test("returns a list which is not the given one", () {
      final list = [1];

      ListUtility.copy(list).add(2);

      expect(list, [1]);
    });

    test("returns a list which cannot grow when it is asked to", () {
      final copy = ListUtility.copy([1], growable: false);

      expect(() => copy.add(2), throwsUnsupportedError);
    });
  });

  group("ListUtility.copyWithoutValue", () {
    test("removes every occurrence of the value", () {
      expect(ListUtility.copyWithoutValue([1, 2, 1], 1), [2]);
    });

    test("returns a list which cannot grow when it is asked to", () {
      final copy = ListUtility.copyWithoutValue([1, 2], 1, growable: false);

      expect(() => copy.add(3), throwsUnsupportedError);
    });
  });

  group("ListUtility.copyWithoutValues", () {
    test("removes every occurrence of every value", () {
      expect(ListUtility.copyWithoutValues([1, 2, 3, 1], [1, 3]), [2]);
    });
  });

  group("ListUtility.getListsIntersection", () {
    test("only keeps the elements which are in every list", () {
      expect(
        ListUtility.getListsIntersection([
          [1, 2, 3],
          [2, 3, 4],
          [3, 2],
        ]),
        unorderedEquals([2, 3]),
      );
    });

    test("returns an empty list when the lists share nothing", () {
      expect(
        ListUtility.getListsIntersection([
          [1],
          [2],
        ]),
        isEmpty,
      );
    });

    test("returns the only list it is given", () {
      expect(
        ListUtility.getListsIntersection([
          [1, 2],
        ]),
        unorderedEquals([1, 2]),
      );
    });

    test("returns an empty list when there is no list at all", () {
      expect(ListUtility.getListsIntersection(<List<int>>[]), isEmpty);
    });
  });

  group("ListUtility.interleave", () {
    test("inserts the value between the elements", () {
      expect(ListUtility.interleave([1, 2, 3], 0), [1, 0, 2, 0, 3]);
    });

    test("adds the value before the first element when it is asked to", () {
      expect(ListUtility.interleave([1, 2], 0, addLeft: true), [0, 1, 0, 2]);
    });

    test("adds the value after the last element when it is asked to", () {
      expect(ListUtility.interleave([1, 2], 0, addRight: true), [1, 0, 2, 0]);
    });

    test("returns an empty list for an empty one, whatever the ends ask for", () {
      expect(ListUtility.interleave(<int>[], 0, addLeft: true, addRight: true), isEmpty);
    });

    test("returns the only element of a list of one, without any interleave", () {
      expect(ListUtility.interleave([1], 0), [1]);
    });
  });

  group("ListUtility.interleaveWithBuilder", () {
    test("builds a new interleave for every insertion", () {
      var built = 0;

      final list = ListUtility.interleaveWithBuilder([1, 2, 3], () => --built);

      expect(list, [1, -1, 2, -2, 3]);
    });

    test("does not build any interleave for an empty list", () {
      var built = 0;

      ListUtility.interleaveWithBuilder(<int>[], () => ++built, addLeft: true, addRight: true);

      expect(built, 0);
    });
  });

  group("ListUtility.testIfAtLeastOneIsInList", () {
    test("returns true when one element is in the list", () {
      expect(ListUtility.testIfAtLeastOneIsInList([3, 1], [1, 2]), isTrue);
    });

    test("returns false when no element is in the list", () {
      expect(ListUtility.testIfAtLeastOneIsInList([3], [1, 2]), isFalse);
    });
  });

  group("ListUtility.testIfListIsInList", () {
    test("returns true when every element is in the list", () {
      expect(ListUtility.testIfListIsInList([1, 2], [1, 2, 3]), isTrue);
    });

    test("returns false when one element is missing", () {
      expect(ListUtility.testIfListIsInList([1, 4], [1, 2, 3]), isFalse);
    });
  });

  group("ListUtility.safeSublist", () {
    test("returns the elements between the two indexes", () {
      expect(ListUtility.safeSublist([1, 2, 3, 4], 1, 3), [2, 3]);
    });

    test("goes to the end of the list when no end is given", () {
      expect(ListUtility.safeSublist([1, 2, 3], 1), [2, 3]);
    });

    test("starts at the beginning when the start is negative", () {
      expect(ListUtility.safeSublist([1, 2, 3], -2, 2), [1, 2]);
    });

    test("stops at the end of the list when the end overflows it", () {
      expect(ListUtility.safeSublist([1, 2], 0, 10), [1, 2]);
    });

    test("returns an empty list when the start overflows the list", () {
      expect(ListUtility.safeSublist([1, 2], 5), isEmpty);
    });

    test("returns an empty list when the end is before the start", () {
      expect(ListUtility.safeSublist([1, 2, 3], 2, 1), isEmpty);
    });

    test("returns an empty list when the end is negative", () {
      expect(ListUtility.safeSublist([1, 2, 3], 0, -1), isEmpty);
    });

    test("returns an empty list for an empty one", () {
      expect(ListUtility.safeSublist(<int>[], 0, 3), isEmpty);
    });
  });

  group("ListUtility.safeSublistFromLength", () {
    test("returns the asked number of elements from the start", () {
      expect(ListUtility.safeSublistFromLength([1, 2, 3, 4], 1, 2), [2, 3]);
    });

    test("goes to the end of the list when no length is given", () {
      expect(ListUtility.safeSublistFromLength([1, 2, 3], 1), [2, 3]);
    });

    test("stops at the end of the list when the length overflows it", () {
      expect(ListUtility.safeSublistFromLength([1, 2], 0, 10), [1, 2]);
    });

    test("returns an empty list when the length is negative", () {
      expect(ListUtility.safeSublistFromLength([1, 2, 3], 1, -1), isEmpty);
    });
  });

  group("ListUtility.distinct", () {
    test("removes the duplicated elements and keeps the order", () {
      expect(ListUtility.distinct([3, 1, 3, 2, 1]), [3, 1, 2]);
    });

    test("keeps the first occurrence of a duplicated element", () {
      final list = ListUtility.distinct(
        [const _Item("a", 1), const _Item("b", 1), const _Item("a", 2)],
        getUniqueElem: (item) => item.name,
      );

      expect(list.map((item) => item.version).toList(), [1, 1]);
    });

    test("leaves the given list untouched", () {
      final list = [1, 1];

      ListUtility.distinct(list);

      expect(list, [1, 1]);
    });

    test("returns an empty list for an empty one", () {
      expect(ListUtility.distinct(<int>[]), isEmpty);
    });
  });

  group("ListUtility.moveElement", () {
    test("moves an element forward, before the element at the targeted index", () {
      final list = ["a", "b", "c", "d"];

      ListUtility.moveElement(list, 0, 2);

      expect(list, ["b", "a", "c", "d"]);
    });

    test("moves an element to the end when the targeted index is the list length", () {
      final list = ["a", "b", "c", "d"];

      ListUtility.moveElement(list, 0, 4);

      expect(list, ["b", "c", "d", "a"]);
    });

    test("moves an element backward", () {
      final list = ["a", "b", "c"];

      ListUtility.moveElement(list, 2, 0);

      expect(list, ["c", "a", "b"]);
    });

    test("does nothing when the current index is outside of the list", () {
      final list = ["a", "b"];

      ListUtility.moveElement(list, 2, 0);
      ListUtility.moveElement(list, -1, 0);

      expect(list, ["a", "b"]);
    });

    test("does nothing when the targeted index is outside of the list", () {
      final list = ["a", "b"];

      ListUtility.moveElement(list, 0, 3);
      ListUtility.moveElement(list, 0, -1);

      expect(list, ["a", "b"]);
    });
  });

  group("ListUtility.appendOrReplace", () {
    test("appends the list when no start is given", () {
      expect(ListUtility.appendOrReplace([1, 2], [3]), [1, 2, 3]);
    });

    test("appends the list when the start is the list length", () {
      expect(ListUtility.appendOrReplace([1, 2], [3], 2), [1, 2, 3]);
    });

    test("replaces the elements from the start", () {
      expect(ListUtility.appendOrReplace([1, 2, 3], [8, 9], 1), [2, 3, 8, 9]);
    });

    test("returns an empty list when the start overflows the list", () {
      expect(ListUtility.appendOrReplace([1, 2], [3], 5), isEmpty);
    });

    test("leaves the given list untouched", () {
      final list = [1, 2];

      ListUtility.appendOrReplace(list, [3]);

      expect(list, [1, 2]);
    });
  });

  group("ListUtility.indexWhereOrNull", () {
    test("returns the index of the first matching element", () {
      expect(ListUtility.indexWhereOrNull([1, 2, 4], (element) => element.isEven), 1);
    });

    test("returns null when no element matches", () {
      expect(ListUtility.indexWhereOrNull([1, 3], (element) => element.isEven), isNull);
    });

    test("starts the search at the given index", () {
      expect(ListUtility.indexWhereOrNull([2, 3, 4], (element) => element.isEven, start: 1), 2);
    });

    test("returns null when the start overflows the list", () {
      expect(ListUtility.indexWhereOrNull([1, 2], (element) => true, start: 5), isNull);
    });

    test("starts at the beginning when the start is negative", () {
      expect(ListUtility.indexWhereOrNull([1, 2], (element) => true, start: -3), 0);
    });
  });

  group("ListUtility.indexWhereOrDefault", () {
    test("returns the index of the first matching element", () {
      expect(ListUtility.indexWhereOrDefault([1, 2], (element) => element.isEven), 1);
    });

    test("returns the not found index when no element matches", () {
      expect(
        ListUtility.indexWhereOrDefault([1, 3], (element) => element.isEven),
        ListUtility.defaultIndexOfValueNotFound,
      );
    });

    test("returns the given default value when no element matches", () {
      expect(
        ListUtility.indexWhereOrDefault([1, 3], (element) => element.isEven, defaultValue: 42),
        42,
      );
    });

    test("returns the default value when the start overflows the list", () {
      expect(
        ListUtility.indexWhereOrDefault([1], (element) => true, start: 5, defaultValue: 42),
        42,
      );
    });
  });

  group("ListUtility.indexesWhere", () {
    test("returns every index where the test passes", () {
      expect(ListUtility.indexesWhere([1, 2, 3, 4], (element) => element.isEven), [1, 3]);
    });

    test("returns an empty list when no element matches", () {
      expect(ListUtility.indexesWhere([1, 3], (element) => element.isEven), isEmpty);
    });

    test("starts the search at the given index", () {
      expect(ListUtility.indexesWhere([2, 3, 4], (element) => element.isEven, start: 1), [2]);
    });

    test("stops once the maximum count is reached", () {
      expect(
        ListUtility.indexesWhere([2, 4, 6], (element) => element.isEven, maxCount: 2),
        [0, 1],
      );
    });

    test("returns an empty list when the maximum count is zero", () {
      expect(ListUtility.indexesWhere([2, 4], (element) => true, maxCount: 0), isEmpty);
    });

    test("returns an empty list when the start overflows the list", () {
      expect(ListUtility.indexesWhere([1, 2], (element) => true, start: 5), isEmpty);
    });

    test("returns an empty list for an empty one", () {
      expect(ListUtility.indexesWhere(<int>[], (element) => true), isEmpty);
    });
  });

  group("ListUtility.lastIndexesWhere", () {
    test("returns the indexes from the end of the list", () {
      expect(ListUtility.lastIndexesWhere([1, 2, 3, 4], (element) => element.isEven), [3, 1]);
    });

    test("starts the search at the given index and goes backward", () {
      expect(ListUtility.lastIndexesWhere([2, 3, 4], (element) => element.isEven, start: 1), [0]);
    });

    test("starts at the last index when the start overflows the list", () {
      expect(ListUtility.lastIndexesWhere([1, 2], (element) => element.isEven, start: 9), [1]);
    });

    test("returns an empty list when the start is negative", () {
      expect(ListUtility.lastIndexesWhere([1, 2], (element) => true, start: -1), isEmpty);
    });

    test("stops once the maximum count is reached", () {
      expect(
        ListUtility.lastIndexesWhere([2, 4, 6], (element) => element.isEven, maxCount: 2),
        [2, 1],
      );
    });

    test("returns an empty list for an empty one", () {
      expect(ListUtility.lastIndexesWhere(<int>[], (element) => true), isEmpty);
    });
  });
}
