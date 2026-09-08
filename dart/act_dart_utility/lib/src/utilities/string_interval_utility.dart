// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/string_interval.dart';
import 'package:act_dart_utility/src/utilities/list_utility.dart';

/// This class is used to manage string intervals
sealed class StringIntervalUtility {
  /// This method allows to act on intervals of a string, the intervals are defined by the keys
  /// given.
  ///
  /// The [transform] method is applied to each interval, and then the [merge] method is applied to
  /// the list of transformed intervals in order to merge them into a single element.
  static FinalElement actOnInterval<FinalElement, SubElement>(
    String text,
    List<String> keys,
    SubElement Function(StringInterval interval) transform,
    FinalElement Function(List<SubElement> elements) merge,
  ) {
    final intervals = getIntervals(text, keys);
    final transformedElements = intervals.map(transform).toList(growable: false);

    return merge(transformedElements);
  }

  /// This method gets the string intervals thanks to the keys given
  ///
  /// no intervals returned intersects between themselves, say otherwise: each character of the
  /// [text] given is in one, and only one, interval
  ///
  /// This methods will also creates interval for the elements not pointed by keys (they have null
  /// key)
  ///
  /// The order of the list is also the order of importance, if a key is in an another key, the last
  /// key in the list order will prevail for the interval.
  /// For instance, for the keys: ["ber"] and text: "Cumbersome" this will creates three intervals:
  /// [ cum, ber, some ]
  ///
  /// Empty key is ignored, otherwise it would create too much intervals.
  ///
  /// If a key is duplicated, it will be only processed once (the first occurrence in the list will
  /// be processed, the others will be ignored).
  static List<StringInterval> getIntervals(String text, List<String> keys) {
    var filteredKeys = keys.where((key) => key.isNotEmpty).toList();
    filteredKeys = ListUtility.distinct(filteredKeys);

    return flatIntervals(text, filteredKeys, findIntervals(text, filteredKeys));
  }

  /// This methods finds all the string intervals thanks to the keys given
  ///
  /// The intervals can intersects between themselves
  /// For instance and for the keys: [ "ber"] and text: "Cumbersome" this will creates one
  /// interval: [ "ber" ]
  ///
  /// Empty key is ignored, otherwise it would create too much intervals.
  static Map<String, List<StringInterval>> findIntervals(
    String text,
    List<String> keys,
  ) {
    final textIntervals = <String, List<StringInterval>>{};

    for (final key in keys) {
      if (key.isEmpty || textIntervals.containsKey(key)) {
        // We don't want to find empty key, it would create too much intervals
        // We also want to avoid to process the same key several times
        continue;
      }

      var idx = 0;
      final length = key.length;
      textIntervals[key] = [];

      while (idx != -1) {
        idx = text.indexOf(key, idx);

        if (idx != -1) {
          textIntervals[key]!.add(StringInterval(
            key: key,
            startIdx: idx,
            length: length,
          ));

          // To avoid to find always the same element
          idx++;
        }
      }
    }

    return textIntervals;
  }

  /// This method will flatten intervals in order to avoid that some intervals intersect between
  /// themselves.
  ///
  /// This will also adds intervals for characters which aren't pointed by a key.
  ///
  /// After the call of this method, every character is in one and only one interval
  static List<StringInterval> flatIntervals(
    String text,
    List<String> keys,
    Map<String, List<StringInterval>> intervalsToFlat,
  ) {
    final flattenTextIntervals = <StringInterval>[];

    final tmpKeys = List<String>.from(keys);

    var idxWithoutChange = 0;
    String? currentKey;

    for (var index = 0; index < text.length; index++) {
      String? keyFound;

      // We begin with the last key because it's the most important element to
      // highlight
      for (var keyIdx = (tmpKeys.length - 1); keyIdx >= 0; keyIdx--) {
        final key = tmpKeys.elementAt(keyIdx);

        final tmpInter = intervalsToFlat[key]!;

        // Clean interval list in order to avoid redundant searching
        _cleanIntervalList(index, tmpInter);

        if (tmpInter.isEmpty) {
          // Remove key => it's no more useful for the search
          tmpKeys.removeAt(keyIdx);
          continue;
        }

        if (tmpInter.first.placeInRelationToInterval(index) == -1) {
          // The element is before the first key interval
          continue;
        }

        keyFound = key;
        break;
      }

      if (currentKey != keyFound) {
        if (index != 0) {
          flattenTextIntervals.add(StringInterval.withEndIdx(
            key: currentKey,
            startIdx: idxWithoutChange,
            endIdx: index - 1,
          ));
        }

        currentKey = keyFound;
        idxWithoutChange = index;
      }

      if (index == text.length - 1) {
        // Add the last interval
        flattenTextIntervals.add(StringInterval.withEndIdx(
          key: currentKey,
          startIdx: idxWithoutChange,
          endIdx: index,
        ));
      }
    }

    return flattenTextIntervals;
  }

  /// This method removes intervals which are already dealt by the method, and
  /// there where there end index is under the current index
  static void _cleanIntervalList(int index, List<StringInterval> intervals) {
    while (intervals.isNotEmpty) {
      if (intervals.first.endIdx >= index) {
        // Useless to go after
        break;
      }

      intervals.removeAt(0);
    }
  }
}
