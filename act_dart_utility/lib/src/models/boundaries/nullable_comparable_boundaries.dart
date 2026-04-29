// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/boundaries/custom_comparable_boundaries.dart';

/// {@macro act_dart_utility.ComparableBoundaries}
///
/// Min and max boundaries can be null.
class NullableComparableBoundaries<T extends Comparable<T>>
    extends CustomComparableBoundaries<T?, T?, T, T> {
  /// Class constructor
  NullableComparableBoundaries({super.min, super.max});

  /// Create a copy of this [NullableComparableBoundaries] with the given parameters.
  NullableComparableBoundaries copyWith({
    T? min,
    bool forceMinValue = false,
    T? max,
    bool forceMaxValue = false,
  }) => NullableComparableBoundaries<T>(
    min: min ?? (forceMinValue ? null : this.min),
    max: max ?? (forceMaxValue ? null : this.max),
  );
}
