// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/boundaries/custom_comparable_boundaries.dart';

/// {@macro act_dart_utility.ComparableBoundaries}
///
/// Min and max boundaries can be null.
class NullableNumBoundaries<T extends num> extends CustomComparableBoundaries<T?, T?, T, num> {
  /// Class constructor
  NullableNumBoundaries({super.min, super.max});

  /// Create a copy of this [NullableNumBoundaries] with the given parameters.
  NullableNumBoundaries<T> copyWith({
    T? min,
    bool forceMinValue = false,
    T? max,
    bool forceMaxValue = false,
  }) => NullableNumBoundaries<T>(
    min: min ?? (forceMinValue ? null : this.min),
    max: max ?? (forceMaxValue ? null : this.max),
  );
}
