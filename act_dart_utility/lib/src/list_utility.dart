// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 - 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Helpful class to manage lists
class ListUtility {
  /// Return a copy of [list]
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  static List<T> copy<T>(List<T> list, {bool growable = true}) =>
      List<T>.from(list, growable: growable);

  /// Return a copy of [list], with all occurrences of [value] removed
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  static List<T> copyWithoutValue<T>(List<T> list, T? value, {bool growable = true}) =>
      list.where((cell) => cell != value).toList(growable: growable);

  /// Return a copy of [list], with all occurrences of [values] removed
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  static List<T> copyWithoutValues<T>(List<T> list, List<T> values, {bool growable = true}) =>
      list.where((cell) => !values.contains(cell)).toList(growable: growable);

  /// Only returns the elements which are contained in all the given lists
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
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

  /// Return a given [list] with [interleave] value inserted between each [list] item.
  static List<T> interleave<T>(List<T> list, T interleave) =>
      interleaveWithBuilder(list, () => interleave);

  /// Return a given [list] with built interleaves inserted between each [list] item.
  static List<T> interleaveWithBuilder<T>(List<T> list, T Function() interleaveBuilder) =>
      list.fold(
        <T>[],
        (previousValue, element) =>
            previousValue.isEmpty ? [element] : [...previousValue, interleaveBuilder(), element],
      );

  /// Test if at least one element of [atLeastOne] list is contained in the [globalList] list
  static bool testIfAtLeastOneIsInList<T>(List<T> atLeastOne, List<T> globalList) {
    for (final element in atLeastOne) {
      if (globalList.contains(element)) {
        return true;
      }
    }

    return false;
  }

  /// Test if all the elements of [mustBeIn] list are in the [globalList] list
  static bool testIfListIsInList<T>(List<T> mustBeIn, List<T> globalList) {
    for (final element in mustBeIn) {
      if (!globalList.contains(element)) {
        return false;
      }
    }

    return true;
  }

  /// Returns a new list containing the elements between [start] and [end]. The [end] is not
  /// included.
  ///
  /// The method always returns a list:
  ///
  /// - If [start] is negative, 0 will be used.
  /// - If [start] overflows the list length, an empty list will be returned
  /// - If [end] is null or overflow the list length, the list length will be used.
  /// - If [end] is negative or before [start], an empty list will be returned.
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

  /// Returns a new list containing the elements which begins at [start] and with the given
  /// [length].
  ///
  /// The method always returns a list:
  ///
  /// - If [start] is negative, 0 will be used.
  /// - If [start] overflows the list length, an empty list will be returned
  /// - If [length] is null or overflow the list length with [start], the list length will be used.
  /// - If [length] is negative, an empty list will be returned.
  static List<T> safeSublistFromLength<T>(List<T> list, int start, [int? length]) =>
      safeSublist(list, start, (length != null) ? start + length : null);

  /// Returns a new list (in the same order as the given [list]) without any duplicated element.
  ///
  /// If the list objects are complexes, you can use the [getUniqueElem] method to extra an unique
  /// testable element from them.
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

  /// {@template ListUtility.moveElement}
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
}
