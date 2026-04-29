// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/utilities/comparable_utility.dart';
import 'package:equatable/equatable.dart';

/// {@template act_dart_utility.ComparableBoundaries}
/// This class contains [min] and [max] values to be compared with.
/// {@endtemplate}
///
/// We advice you to use one of the typedefs of this class, depending on your needs regarding
/// nullability of the boundaries instead of using [CustomComparableBoundaries] directly.
class CustomComparableBoundaries<
  Min extends T?,
  Max extends T?,
  T extends Comp,
  Comp extends Comparable<Comp>
>
    extends Equatable {
  /// This is the [min] boundary.
  ///
  /// If null, we consider there is no min boundary.
  final Min min;

  /// This is the [max] boundary.
  ///
  /// If null, we consider there is no max boundary.
  final Max max;

  /// Class constructor
  CustomComparableBoundaries({required this.min, required this.max})
    : assert(
        _isMinMaxValid<Comp>(min: min, max: max),
        "The $min value shouldn't be greather then $max",
      );

  /// Test if the given [value] is in the [min] and [max] boundaries.
  ///
  /// If [min] or [max] are null, we don't test the boundary.
  ///
  /// If [strictCompare] is equal to true, we return true if the value is equal to one of the
  /// boundary.
  bool isInBoundaries(T value, {bool strictCompare = false}) {
    if (null is! Min || min != null) {
      if (!ComparableUtility.isBaseLesserOrEqualTo<Comp>(
        base: min!,
        toCompareWith: value,
        testEquality: !strictCompare,
      )) {
        return false;
      }
    }

    if (null is! Max || max != null) {
      if (!ComparableUtility.isBaseGreaterOrEqualTo<Comp>(
        base: max!,
        toCompareWith: value,
        testEquality: !strictCompare,
      )) {
        return false;
      }
    }

    return true;
  }

  /// This method allows to check if the [min] and [max] boundaries are valid, meaning that
  /// the [min] value is lesser than the [max] value.
  static bool _isMinMaxValid<Comp extends Comparable<Comp>>({
    required Comp? min,
    required Comp? max,
  }) => min == null || max == null || min.compareTo(max) <= 0;

  /// Class properties
  @override
  List<Object?> get props => [min, max];
}
