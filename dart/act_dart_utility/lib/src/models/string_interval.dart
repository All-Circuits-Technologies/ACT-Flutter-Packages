// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This class is used to represent an interval of a string, with a start index and an end index.
/// It also contains a key that can be used to link the interval to a specific word or part of the
/// string.
class StringInterval {
  /// This is the linked key to the interval.
  ///
  /// This can be null if the interval is not linked to any key, for example if the interval is for
  /// characters that aren't pointed by any key.
  final String? key;

  /// This is the start index of the text interval.
  int startIdx;

  /// This is the end index of the text interval.
  int endIdx;

  /// Default class constructor with a given length.
  StringInterval({
    required this.key,
    required this.startIdx,
    required int length,
  }) : endIdx = (startIdx + (length - 1));

  /// Class constructor with the end index.
  StringInterval.withEndIdx({
    required this.key,
    required this.startIdx,
    required this.endIdx,
  });

  /// Compare the [index] with the interval.
  ///
  /// If the [index] is in the interval returns 0.
  /// If the [index] is under the interval returns -1.
  /// If the [index] is above the interval returns 1.
  int placeInRelationToInterval(int index) {
    if (index < startIdx) {
      return -1;
    }

    if (index > endIdx) {
      return 1;
    }

    return 0;
  }

  /// Get the characters managed by the interval in the [str] given.
  ///
  /// Be careful to give to this method the same [str] as the one you build the interval with.
  String getIntervalString(String str) => str.substring(startIdx, endIdx + 1);
}
