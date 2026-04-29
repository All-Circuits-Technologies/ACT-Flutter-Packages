// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/boundaries/custom_comparable_boundaries.dart';

/// {@macro act_dart_utility.ComparableBoundaries}
///
/// Min and max boundaries can't be null.
class ComparableBoundaries<T extends Comparable<T>> extends CustomComparableBoundaries<T, T, T, T> {
  /// Class constructor
  ComparableBoundaries({required super.min, required super.max});

  /// Create a copy of this [ComparableBoundaries] with the given parameters.
  ComparableBoundaries<T> copyWith({T? min, T? max}) =>
      ComparableBoundaries<T>(min: min ?? this.min, max: max ?? this.max);
}
