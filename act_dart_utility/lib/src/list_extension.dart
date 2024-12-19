// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/list_utility.dart';

// Note to developers:
// Do not implement smart stuff here. Implement them as static methods within [ListUtility]
// and mirror them here.

/// This [List] extension helps generating lists results
extension ActListGen<T> on List<T> {
  /// Return a copy of current list
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  List<T> copy({bool growable = true}) => ListUtility.copy(this, growable: growable);

  /// Return a copy of current list, with all occurrences of [value] removed
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  List<T> copyWithoutValue(T? value, {bool growable = true}) =>
      ListUtility.copyWithoutValue(this, value, growable: growable);

  /// Return a copy of current list, with all occurrences of [values] removed
  ///
  /// Copy is growable by default, but can be set to not growable using [growable] argument.
  List<T> copyWithoutValues(List<T> values, {bool growable = true}) =>
      ListUtility.copyWithoutValues(this, values, growable: growable);

  /// Return a list copy with [interleave] value inserted between each item.
  ///
  /// ```dart
  /// listEquals(
  ///     [1, 2, 3].interleave(0),
  ///     [1, 0, 2, 0, 3],
  /// );
  /// ```
  List<T> interleave(T interleave) => ListUtility.interleave(this, interleave);

  /// Return a list copy with built interleaves inserted between each item.
  ///
  /// ```dart
  /// listEquals(
  ///     [1, 2, 3].interleave(() => 0),
  ///     [1, 0, 2, 0, 3],
  /// );
  /// ```
  List<T> interleaveWithBuilder(T Function() interleaveBuilder) =>
      ListUtility.interleaveWithBuilder(this, interleaveBuilder);

  /// Returns a new list containing the elements between [start] and [end]. The [end] is not
  /// included.
  ///
  /// The method always returns a list:
  ///
  /// - If [start] is negative, 0 will be used.
  /// - If [start] overflows the list length, an empty list will be returned
  /// - If [end] is null or overflow the list length, the list length will be used.
  /// - If [end] is negative or before [start], an empty list will be returned.
  List<T> safeSublist(int start, [int? end]) => ListUtility.safeSublist(this, start, end);

  /// Returns a new list containing the elements which begins at [start] and with the given
  /// [length].
  ///
  /// The method always returns a list:
  ///
  /// - If [start] is negative, 0 will be used.
  /// - If [start] overflows the list length, an empty list will be returned
  /// - If [length] is null or overflow the list length with [start], the list length will be used.
  /// - If [length] is negative, an empty list will be returned.
  List<T> safeSublistFromLength(int start, [int? length]) =>
      ListUtility.safeSublistFromLength(this, start, length);

  /// Returns a new list (in the same order as the list) without any duplicated element.
  ///
  /// If the list objects are complexes, you can use the [getUniqueElem] method to extra an unique
  /// testable element from them.
  List<T> distinct<Y extends Object?>({
    Y Function(T item)? getUniqueElem,
  }) =>
      ListUtility.distinct<T, Y>(
        this,
        getUniqueElem: getUniqueElem,
      );

  /// {@macro ListUtility.moveElement}
  void moveElement(int currentIdx, int targetedIdx) => ListUtility.moveElement<T>(
        this,
        currentIdx,
        targetedIdx,
      );

  /// {@macro ListUtility.addOrReplace}
  List<T> appendOrReplace(List<T> listToAdd, [int? start]) => ListUtility.appendOrReplace(
        this,
        listToAdd,
        start,
      );
}
