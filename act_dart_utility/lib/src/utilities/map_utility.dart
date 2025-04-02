// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Helpful class to manage maps
sealed class MapUtility {
  /// {@template act_dart_utility.ListUtility.copy}
  /// Return a copy of [map]
  /// {@endtemplate}
  static Map<K, V> copy<K, V>(Map<K, V> map) => Map<K, V>.from(map);

  /// {@template act_dart_utility.MapUtility.copyAndMerge}
  /// Merge the [toMerge] map into a copy of [map].
  ///
  /// If [toMerge] is null, this returns a copy of [map].
  /// {@endtemplate}
  static Map<K, V> copyAndMerge<K, V>(Map<K, V> map, Map<K, V>? toMerge) {
    final tmpMap = Map<K, V>.from(map);
    if (toMerge == null) {
      return tmpMap;
    }

    tmpMap.addAll(toMerge);
    return tmpMap;
  }

  /// {@template act_dart_utility.MapUtility.copyAndMergeOrNull}
  /// Merge the [toMerge] map into a copy of [map].
  ///
  /// If [toMerge] is null or empty, this returns null.
  /// {@endtemplate}
  static Map<K, V>? copyAndMergeOrNull<K, V>(Map<K, V> map, Map<K, V>? toMerge) {
    if (toMerge == null || toMerge.isEmpty) {
      return null;
    }

    final tmpMap = Map<K, V>.from(map);
    tmpMap.addAll(toMerge);
    return tmpMap;
  }
}
