// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/boundaries/custom_comparable_boundaries.dart';

/// {@macro act_dart_utility.ComparableBoundaries}
///
/// Min and max boundaries can't be null.
class NumBoundaries<T extends num> extends CustomComparableBoundaries<T, T, T, num> {
  /// Class constructor
  NumBoundaries({required super.min, required super.max});

  /// Create a copy of this [NumBoundaries] with the given parameters.
  NumBoundaries<T> copyWith({T? min, T? max}) =>
      NumBoundaries<T>(min: min ?? this.min, max: max ?? this.max);
}
