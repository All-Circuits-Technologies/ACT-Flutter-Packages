// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/boundaries/custom_comparable_boundaries.dart';

/// {@macro act_dart_utility.ComparableBoundaries}
///
/// Max can be null, but min can't be null.
class NullableMaxNumBoundaries<T extends num> extends CustomComparableBoundaries<T, T?, T, num> {
  /// Class constructor
  NullableMaxNumBoundaries({required super.min, super.max});

  /// Create a copy of this [NullableMaxNumBoundaries] with the given parameters.
  NullableMaxNumBoundaries<T> copyWith({T? min, T? max, bool forceMaxValue = false}) =>
      NullableMaxNumBoundaries<T>(
        min: min ?? this.min,
        max: max ?? (forceMaxValue ? null : this.max),
      );
}
