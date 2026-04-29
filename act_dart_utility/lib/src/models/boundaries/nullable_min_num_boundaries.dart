// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/boundaries/custom_comparable_boundaries.dart';

/// {@macro act_dart_utility.ComparableBoundaries}
///
/// Min can be null, but max can't be null.
class NullableMinNumBoundaries<T extends num> extends CustomComparableBoundaries<T?, T, T, num> {
  /// Class constructor
  NullableMinNumBoundaries({required super.max, super.min});

  /// Create a copy of this [NullableMinNumBoundaries] with the given parameters.
  NullableMinNumBoundaries copyWith({T? min, bool forceMinValue = false, T? max}) =>
      NullableMinNumBoundaries<T>(
        min: min ?? (forceMinValue ? null : this.min),
        max: max ?? this.max,
      );
}
