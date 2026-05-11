// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math' as Math;

/// This library provides utility functions for math operations.
sealed class MathUtility {
  /// {@template act_dart_utility.MathUtility.degreesToRadians}
  /// Convert an angle in degrees to radians.
  /// {@endtemplate}
  static double degreesToRadians(double degrees) => degrees * (Math.pi / 180);

  /// {@template act_dart_utility.MathUtility.radiansToDegrees}
  /// Convert an angle in radians to degrees.
  /// {@endtemplate}
  static double radiansToDegrees(double radians) => radians * (180 / Math.pi);
}
