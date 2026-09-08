// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Helpful class to manage String lists
sealed class StringListUtility {
  /// {@template act_dart_utility.StringListUtility.trim}
  /// Return a copy of [list] without empty strings at the beginning and at the end. We keep the
  /// empty strings in the middle of the list.
  ///
  /// For instance: `['', 'a', 'b', '', 'c', '']` will return `['a', 'b', '', 'c']`
  /// {@endtemplate}
  static List<String> trim(List<String> list, {bool growable = true}) {
    if (list.isEmpty) {
      return List<String>.empty(growable: growable);
    }

    final length = list.length;
    var offset = 0;
    var end = length;

    if (list.elementAt(0).isEmpty) {
      offset = 1;
    }

    if (length > 1 && list.elementAt(length - 1).isEmpty) {
      end -= 1;
    }

    return list.sublist(offset, end);
  }
}
