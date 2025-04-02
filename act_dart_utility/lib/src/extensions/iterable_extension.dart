// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/utilities/iterable_utility.dart';

// Note to developers:
// Do not implement smart stuff here. Implement them as static methods within [IterableUtility]
// and mirror them here.

/// This [Iterable] extension helps finding element(s) inside Iterables
extension ActIterableLookup<T> on Iterable<T> {
  /// Return first item of current collection matching a given [predicate], null otherwise
  T? firstWhereOrNull(bool Function(T element) predicate) =>
      IterableUtility.firstWhereOrNull(this, predicate);

  /// Return a copy of current collection, with all occurrences of [value] removed
  Iterable<T> copyWithoutValue(T? value) => IterableUtility.copyWithoutValue<T>(this, value);

  /// Return a copy of current collection, with all occurrences of [values] removed
  Iterable<T> copyWithoutValues(Iterable<T> values) =>
      IterableUtility.copyWithoutValues(this, values);

  /// Test if at least one element of [atLeastOne] collection is contained in the current collection
  bool testIfAtLeastOneIsInCollection(
    Iterable<T> atLeastOne,
  ) =>
      IterableUtility.testIfAtLeastOneIsInCollection(atLeastOne, this);

  /// Test if all the elements of [mustBeIn] collection are in the current collection
  bool testIfListIsInCollection(Iterable<T> mustBeIn) =>
      IterableUtility.testIfListIsInCollection(mustBeIn, this);
}
