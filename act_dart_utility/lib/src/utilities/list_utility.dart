// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 - 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 - 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/utilities/iterable_utility.dart';

/// Helpful class to manage lists
sealed class ListUtility {
  /// {@template act_dart_utility.ListUtility.copy}
  /// Return a copy of [list]
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  /// {@endtemplate}
  static List<T> copy<T>(List<T> list, {bool growable = true}) =>
      List<T>.from(list, growable: growable);

  /// {@template act_dart_utility.ListUtility.copyWithoutValue}
  /// Return a copy of [list], with all occurrences of [value] removed
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  /// {@endtemplate}
  static List<T> copyWithoutValue<T>(List<T> list, T? value, {bool growable = true}) =>
      IterableUtility.copyWithoutValue(list, value).toList(growable: growable);

  /// {@template act_dart_utility.ListUtility.copyWithoutValues}
  /// Return a copy of [list], with all occurrences of [values] removed
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  /// {@endtemplate}
  static List<T> copyWithoutValues<T>(List<T> list, List<T> values, {bool growable = true}) =>
      IterableUtility.copyWithoutValues(list, values).toList(growable: growable);

  /// {@template act_dart_utility.ListUtility.getListsIntersection}
  /// Only returns the elements which are contained in all the given lists
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  /// {@endtemplate}
  static List<T> getListsIntersection<T>(List<List<T>> elements, {bool growable = true}) {
    if (elements.isEmpty) {
      return [];
    }

    return elements
        .fold<Set<T>>(
          elements.first.toSet(),
          (previousValue, element) => previousValue.intersection(element.toSet()),
        )
        .toList(
          growable: growable,
        );
  }

  /// {@template act_dart_utility.ListUtility.interleave}
  /// Return a given [list] with [interleave] value inserted between each [list] item.
  /// {@endtemplate}
  static List<T> interleave<T>(List<T> list, T interleave) =>
      interleaveWithBuilder(list, () => interleave);

  /// {@template act_dart_utility.ListUtility.interleaveWithBuilder}
  /// Return a given [list] with built interleaves inserted between each [list] item.
  /// {@endtemplate}
  static List<T> interleaveWithBuilder<T>(List<T> list, T Function() interleaveBuilder) =>
      list.fold(
        <T>[],
        (previousValue, element) =>
            previousValue.isEmpty ? [element] : [...previousValue, interleaveBuilder(), element],
      );

  /// {@template act_dart_utility.ListUtility.testIfAtLeastOneIsInList}
  /// Test if at least one element of [atLeastOne] list is contained in the [globalList] list
  /// {@endtemplate}
  static bool testIfAtLeastOneIsInList<T>(List<T> atLeastOne, List<T> globalList) =>
      IterableUtility.testIfAtLeastOneIsInCollection(atLeastOne, globalList);

  /// {@template act_dart_utility.ListUtility.testIfListIsInList}
  /// Test if all the elements of [mustBeIn] list are in the [globalList] list
  /// {@endtemplate}
  static bool testIfListIsInList<T>(List<T> mustBeIn, List<T> globalList) =>
      IterableUtility.testIfListIsInCollection(mustBeIn, globalList);

  /// {@template act_dart_utility.ListUtility.safeSublist}
  /// Returns a new list containing the elements between [start] and [end]. The [end] is not
  /// included.
  ///
  /// The method always returns a list:
  ///
  /// - If [start] is negative, 0 will be used.
  /// - If [start] overflows the list length, an empty list will be returned
  /// - If [end] is null or overflow the list length, the list length will be used.
  /// - If [end] is negative or before [start], an empty list will be returned.
  /// {@endtemplate}
  static List<T> safeSublist<T>(List<T> list, int start, [int? end]) {
    final length = list.length;
    var tmpEnd = end;
    var tmpStart = start;
    if (tmpEnd == null || tmpEnd > length) {
      tmpEnd = length;
    }

    if (tmpStart < 0) {
      tmpStart = 0;
    }

    if (tmpEnd <= 0 || tmpEnd <= tmpStart) {
      return [];
    }

    return list.sublist(tmpStart, tmpEnd);
  }

  /// {@template act_dart_utility.ListUtility.safeSublistFromLength}
  /// Returns a new list containing the elements which begins at [start] and with the given
  /// [length].
  ///
  /// The method always returns a list:
  ///
  /// - If [start] is negative, 0 will be used.
  /// - If [start] overflows the list length, an empty list will be returned
  /// - If [length] is null or overflow the list length with [start], the list length will be used.
  /// - If [length] is negative, an empty list will be returned.
  /// {@endtemplate}
  static List<T> safeSublistFromLength<T>(List<T> list, int start, [int? length]) =>
      safeSublist(list, start, (length != null) ? start + length : null);

  /// {@template act_dart_utility.ListUtility.distinct}
  /// Returns a new list (in the same order as the given [list]) without any duplicated element.
  ///
  /// If the list objects are complexes, you can use the [getUniqueElem] method to extra an unique
  /// testable element from them.
  /// {@endtemplate}
  static List<T> distinct<T, Y extends Object?>(
    List<T> list, {
    Y Function(T item)? getUniqueElem,
  }) {
    final tmpList = List<T>.from(list);

    if (getUniqueElem != null) {
      final uniqueElements = <Y>{};
      tmpList.retainWhere((element) => uniqueElements.add(getUniqueElem(element)));
    } else {
      final uniqueElements = <T>{};
      tmpList.retainWhere(uniqueElements.add);
    }

    return tmpList;
  }

  /// {@template act_dart_utility.ListUtility.moveElement}
  /// Move the item at the [currentIdx] to the [targetedIdx].
  ///
  /// The method modifies the given [list] and doesn't create a new one.
  ///
  /// The given [list] has to be a growable list. If you call this method in a non growable list,
  /// the method will generate an exception.
  ///
  /// [targetedIdx] is an index of the [list] before it is modified. The current element at the same
  /// index is move forward.
  ///
  /// For instance, we have the following list: `[a, b ,c, d]`. If we want to:
  ///
  /// - move `a` between `b` and `c`, we have to call the method with those arguments:
  ///   - `currentIdx` equals to 0 (the current index of `a`)
  ///   - `targetedIdx` equals to 2 (the current index of `c`),
  ///   - `a` will be moved before `c`
  /// - move `a` after `d`, we have to call the method with those arguments:
  ///   - `currentIdx` equals to 0 (the current index of `a`)
  ///   - `targetedIdx` equals to 4 (the list length to add it after `d`),
  ///   - `a` will be moved after `d`
  ///
  /// If [currentIdx] and [targetedIdx] are negative or greater than the list length, this does
  /// nothing
  /// {@endtemplate}
  static void moveElement<T>(List<T> list, int currentIdx, int targetedIdx) {
    final length = list.length;
    if (currentIdx < 0 || currentIdx >= length || targetedIdx < 0 || targetedIdx > length) {
      return;
    }

    final item = list.removeAt(currentIdx);
    var tmpTargetedIdx = targetedIdx;
    if (currentIdx < targetedIdx) {
      tmpTargetedIdx = targetedIdx - 1;
    }
    list.insert(tmpTargetedIdx, item);
  }

  /// {@template act_dart_utility.ListUtility.addOrReplace}
  /// Append or replace the [listToAdd] into the [globalList].
  ///
  /// The method returns a new list with the result.
  ///
  /// If [start] is null, the method will append [listToAdd] to [globalList].
  /// If [start] is between 0 and [globalList] length, the method will replace [globalList] elements
  /// by [listToAdd]. If [listToAdd] length is greater than the elements to replace, the last
  /// elements of [listToAdd] will be appended to the list.
  /// If [start] is greater than the [globalList] length, the method will return an empty list.
  /// {@endtemplate}
  static List<T> appendOrReplace<T>(List<T> globalList, List<T> listToAdd, [int? start]) {
    if (start != null && start > globalList.length) {
      return const [];
    }

    List<T> tmpList;
    if (start == null || start == globalList.length) {
      tmpList = List<T>.from(globalList);
    } else {
      tmpList = ListUtility.safeSublistFromLength(globalList, start);
    }

    tmpList.addAll(listToAdd);
    return tmpList;
  }

  /// {@template act_dart_utility.ListUtility.indexesWhere}
  /// Returns the list of indexes where the [test] function returns true.
  ///
  /// The search starts at the given [start] index.
  ///
  /// If [start] is negative, the search starts at index 0.
  /// If [start] is greater than the list length, an empty list is returned.
  /// If [maxCount] is greater than 0, the method stops the search when the number of found indexes
  /// reaches the [maxCount].
  /// {@endtemplate}
  static List<int> indexesWhere<T>(
    List<T> list,
    bool Function(T element) test, {
    int start = 0,
    int maxCount = -1,
  }) {
    final length = list.length;
    if (maxCount == 0 || length == 0 || start >= length) {
      return [];
    }

    final indexes = <int>[];
    var tmpStart = start;
    if (start < 0) {
      tmpStart = 0;
    }

    for (var idx = tmpStart; idx < length; ++idx) {
      final element = list[idx];
      if (test(element)) {
        indexes.add(idx);
      }

      if (maxCount > 0 && indexes.length >= maxCount) {
        break;
      }
    }

    return indexes;
  }

  /// {@template act_dart_utility.ListUtility.lastIndexesWhere}
  /// Returns the list of indexes where the [test] function returns true.
  ///
  /// The search starts at the given [start] index and goes backward.
  ///
  /// If [start] is null, the search starts at the last index of the list.
  /// If [start] is greater than the list length, the search starts at the last index of the list.
  /// If [start] is negative, an empty list is returned.
  /// If [maxCount] is greater than 0, the method stops the search when the number of found indexes
  /// reaches the [maxCount].
  /// {@endtemplate}
  static List<int> lastIndexesWhere<T>(
    List<T> list,
    bool Function(T element) test, {
    int? start,
    int maxCount = -1,
  }) {
    final length = list.length;
    if (maxCount == 0 || length == 0 || (start != null && start < 0)) {
      return [];
    }

    final indexes = <int>[];
    var tmpStart = start ?? length - 1;
    if (tmpStart >= length) {
      tmpStart = length - 1;
    }

    for (var idx = tmpStart; idx >= 0; --idx) {
      final element = list[idx];
      if (test(element)) {
        indexes.add(idx);
      }

      if (maxCount > 0 && indexes.length >= maxCount) {
        break;
      }
    }

    return indexes;
  }
}
