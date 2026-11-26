// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math' as math;

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("MathUtility.degreesToRadians", () {
    test("converts the usual angles", () {
      expect(MathUtility.degreesToRadians(0), 0);
      expect(MathUtility.degreesToRadians(180), math.pi);
      expect(MathUtility.degreesToRadians(90), math.pi / 2);
    });

    test("keeps the sign of a negative angle", () {
      expect(MathUtility.degreesToRadians(-180), -math.pi);
    });

    test("accepts an angle beyond a full turn", () {
      expect(MathUtility.degreesToRadians(720), closeTo(4 * math.pi, 1e-12));
    });
  });

  group("MathUtility.radiansToDegrees", () {
    test("converts the usual angles", () {
      expect(MathUtility.radiansToDegrees(0), 0);
      expect(MathUtility.radiansToDegrees(math.pi), 180);
      expect(MathUtility.radiansToDegrees(math.pi / 2), 90);
    });

    test("undoes the conversion to radians", () {
      expect(MathUtility.radiansToDegrees(MathUtility.degreesToRadians(42)), closeTo(42, 1e-12));
    });
  });
}
