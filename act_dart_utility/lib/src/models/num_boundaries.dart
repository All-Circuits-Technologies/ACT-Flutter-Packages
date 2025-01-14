// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/utilities/num_utility.dart';
import 'package:equatable/equatable.dart';

/// This class contains [min] and [max] numeric values to be compared with.
class NumBoundaries<T extends num> extends Equatable {
  /// This is the [min] boundary.
  ///
  /// If null, we considere there is no min boundary.
  final T? min;

  /// This is the [max] boundary.
  ///
  /// If null, we considere there is no max boundary.
  final T? max;

  /// Class constructor
  const NumBoundaries({
    this.min,
    this.max,
  }) : assert(min != null && max != null && min <= max, "The $min value is greather then $max");

  /// Test if the given [value] is in the [min] and [max] boundaries.
  ///
  /// If [min] or [max] are null, we don't test the boundary.
  ///
  /// If [strictCompare] is equal to true, we return true if the value is equal to one of the
  /// boundary.
  bool isInBoundaries(
    T value, {
    bool strictCompare = false,
  }) {
    if (min != null) {
      if (!NumUtility.isBaseLesserOrEqualTo<T>(
        base: min!,
        toCompareWith: value,
        testEquality: !strictCompare,
      )) {
        return false;
      }
    }

    if (max != null) {
      if (!NumUtility.isBaseGreatherOrEqualTo<T>(
        base: max!,
        toCompareWith: value,
        testEquality: !strictCompare,
      )) {
        return false;
      }
    }

    return true;
  }

  /// Class properties
  @override
  List<Object?> get props => [min, max];
}
