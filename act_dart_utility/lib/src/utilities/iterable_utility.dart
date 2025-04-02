// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Helpful class to work with Iterables
sealed class IterableUtility {
  /// Return first item of a [collection] matching a given [predicate], null otherwise
  static T? firstWhereOrNull<T>(Iterable<T>? collection, bool Function(T element) predicate) {
    try {
      return collection?.firstWhere(predicate);
    } catch (_) {
      // firstWhere throw a StateError when no items matches predicate
      return null;
    }
  }

  /// Return a copy of [collection], with all occurrences of [value] removed
  static Iterable<T> copyWithoutValue<T>(Iterable<T> collection, T? value) =>
      collection.where((cell) => cell != value);

  /// Return a copy of [collection], with all occurrences of [values] removed
  static Iterable<T> copyWithoutValues<T>(Iterable<T> collection, Iterable<T> values) =>
      collection.where((cell) => !values.contains(cell));

  /// Test if at least one element of [atLeastOne] collection is contained in the [globalCollection]
  /// collection
  static bool testIfAtLeastOneIsInCollection<T>(
    Iterable<T> atLeastOne,
    Iterable<T> globalCollection,
  ) {
    for (final element in atLeastOne) {
      if (globalCollection.contains(element)) {
        return true;
      }
    }

    return false;
  }

  /// Test if all the elements of [mustBeIn] collection are in the [globalCollection] collection
  static bool testIfListIsInCollection<T>(Iterable<T> mustBeIn, Iterable<T> globalCollection) {
    for (final element in mustBeIn) {
      if (!globalCollection.contains(element)) {
        return false;
      }
    }

    return true;
  }
}
