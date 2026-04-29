// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/boundaries/custom_comparable_boundaries.dart';

/// {@macro act_dart_utility.ComparableBoundaries}
///
/// Min can be null, but max can't be null.
class NullableMinComparableBoundaries<T extends Comparable<T>>
    extends CustomComparableBoundaries<T?, T, T, T> {
  /// Class constructor
  NullableMinComparableBoundaries({required super.max, super.min});

  /// Create a copy of this [NullableMinComparableBoundaries] with the given parameters.
  NullableMinComparableBoundaries copyWith({T? min, bool forceMinValue = false, T? max}) =>
      NullableMinComparableBoundaries<T>(
        min: min ?? (forceMinValue ? null : this.min),
        max: max ?? this.max,
      );
}
