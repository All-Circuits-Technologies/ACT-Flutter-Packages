// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/boundaries/custom_comparable_boundaries.dart';

/// {@macro act_dart_utility.ComparableBoundaries}
///
/// Max can be null, but min can't be null.
class NullableMaxComparableBoundaries<T extends Comparable<T>>
    extends CustomComparableBoundaries<T, T?, T, T> {
  /// Class constructor
  NullableMaxComparableBoundaries({required super.min, super.max});

  /// Create a copy of this [NullableMaxComparableBoundaries] with the given parameters.
  NullableMaxComparableBoundaries<T> copyWith({T? min, T? max, bool forceMaxValue = false}) =>
      NullableMaxComparableBoundaries<T>(
        min: min ?? this.min,
        max: max ?? (forceMaxValue ? null : this.max),
      );
}
