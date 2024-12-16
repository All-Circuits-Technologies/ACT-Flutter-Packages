// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Helpful class to manage lists
class ListUtility {
  /// Test if all the elements of [mustBeIn] list are in the [globalList] list
  static bool testIfListIsInList<T>(List<T> mustBeIn, List<T> globalList) {
    for (final element in mustBeIn) {
      if (!globalList.contains(element)) {
        return false;
      }
    }

    return true;
  }

  /// Test if at least one element of [atLeastOne] list is contained in the
  /// [globalList] list
  static bool testIfAtLeastOneIsInList<T>(List<T> atLeastOne, List<T> globalList) {
    for (final element in atLeastOne) {
      if (globalList.contains(element)) {
        return true;
      }
    }

    return false;
  }

  /// Only returns the elements which are contained in all the given lists
  static List<T> getListsIntersection<T>(List<List<T>> elements) {
    if (elements.isEmpty) {
      return [];
    }

    return elements
        .fold<Set<T>>(
          elements.first.toSet(),
          (previousValue, element) => previousValue.intersection(element.toSet()),
        )
        .toList();
  }

  /// The method returns all the elements of [mainList] which aren't contained in [otherList]
  static List<T> getElementsNotContainedInOtherList<T>(
    List<T> mainList,
    List<T> otherList,
  ) {
    final tmpElements = <T>[];

    for (final element in mainList) {
      if (!otherList.contains(element)) {
        tmpElements.add(element);
      }
    }

    return tmpElements;
  }
}
