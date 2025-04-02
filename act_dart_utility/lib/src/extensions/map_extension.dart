// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/utilities/map_utility.dart';

/// This [Map] extension helps finding [MapUtility] methods inside Map
extension ActMapLookup<K, V> on Map<K, V> {
  /// Return a copy of this map
  Map<K, V> copy() => MapUtility.copy(this);

  /// Merge the [toMerge] map into a copy of this map.
  ///
  /// If [toMerge] is null, this returns a copy of this.
  Map<K, V> copyAndMerge(Map<K, V>? toMerge) => MapUtility.copyAndMerge(this, toMerge);

  /// Merge the [toMerge] map into a copy of this collection.
  ///
  /// If [toMerge] is null or empty, this returns null.
  Map<K, V>? copyAndMergeOrNull(Map<K, V>? toMerge) => MapUtility.copyAndMergeOrNull(this, toMerge);
}
