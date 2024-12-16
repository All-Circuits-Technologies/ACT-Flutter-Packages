// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/list_utility.dart';

// Note to developers:
// Do not implement smart stuff here. Implement them as static methods within [ListUtility]
// and mirror them here.

/// This [List] extension helps generating lists results
extension ActListGen<T> on List<T> {
  /// Return a list copy with [interleave] value inserted between each item.
  ///
  /// ```dart
  /// listEquals(
  ///     [1, 2, 3].interleave(0),
  ///     [1, 0, 2, 0, 3],
  /// );
  /// ```
  List<T> interleave(T interleave) => ListUtility.interleave(this, interleave);

  /// Return a list copy with built interleaves inserted between each item.
  ///
  /// ```dart
  /// listEquals(
  ///     [1, 2, 3].interleave(() => 0),
  ///     [1, 0, 2, 0, 3],
  /// );
  /// ```
  List<T> interleaveWithBuilder(T Function() interleaveBuilder) =>
      ListUtility.interleaveWithBuilder(this, interleaveBuilder);
}
