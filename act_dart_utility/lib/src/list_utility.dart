// Copyright (c) 2020. BMS Circuits

/// Helpful class to manage lists
class ListUtility {
  /// Test if all the elements of [mustBeIn] list are in the [globalList] list
  static bool testIfListIsInList<T>(List<T> mustBeIn, List<T> globalList) {
    for (T element in mustBeIn) {
      if (!globalList.contains(element)) {
        return false;
      }
    }

    return true;
  }

  /// Test if at least one element of [atLeastOne] list is contained in the
  /// [globalList] list
  static bool testIfAtLeastOneIsInList<T>(
      List<T> atLeastOne, List<T> globalList) {
    for (T element in atLeastOne) {
      if (globalList.contains(element)) {
        return true;
      }
    }

    return false;
  }
}
