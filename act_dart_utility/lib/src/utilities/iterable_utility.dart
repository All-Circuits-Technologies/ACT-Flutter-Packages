// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Helpful class to work with Iterables
class IterableUtility {
  /// Return first item of a [collection] matching a given [predicate], null otherwise
  static T? firstWhereOrNull<T>(Iterable<T>? collection, bool Function(T element) predicate) {
    try {
      return collection?.firstWhere(predicate);
    } catch (_) {
      // firstWhere throw a StateError when no items matches predicate
      return null;
    }
  }
}
