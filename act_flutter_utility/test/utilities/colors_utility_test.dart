// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A red whose two other channels are empty, so a test reads the redistribution of the overflow of
/// one channel into the others without the noise of a color which already mixes them.
const _pureRed = Color(0xFFFF0000);

void main() {
  group("ColorsUtility.lightingColor", () {
    test("gives back the color it was given when the coefficient changes nothing", () {
      final color = ColorsUtility.lightingColor(baseColor: _pureRed, coeff: 1);

      expect(color, const Color(0xFFFF0000));
    });

    test("keeps the transparency of the color it was given", () {
      final color = ColorsUtility.lightingColor(baseColor: const Color(0x80FF0000), coeff: 1.5);

      expect(color.a, closeTo(0.5, 0.01));
    });

    test("pours the overflow of a channel into the other ones", () {
      final color = ColorsUtility.lightingColor(baseColor: _pureRed, coeff: 1.2);

      expect(color, const Color(0xFFFF1A1A));
    });

    test("turns a color which overflows every channel into white", () {
      final color = ColorsUtility.lightingColor(baseColor: _pureRed, coeff: 10);

      expect(color, const Color(0xFFFFFFFF));
    });

    test("lightens every channel of a grey", () {
      final color = ColorsUtility.lightingColor(baseColor: const Color(0xFF808080), coeff: 1.5);

      expect(color, const Color(0xFFC0C0C0));
    });
  });

  group("ColorsUtility.darkingColor", () {
    test("gives back the color it was given when the coefficient changes nothing", () {
      final color = ColorsUtility.darkingColor(baseColor: _pureRed, coeff: 1);

      expect(color, const Color(0xFFFF0000));
    });

    test("darkens every channel of a grey", () {
      final color = ColorsUtility.darkingColor(baseColor: const Color(0xFF808080), coeff: 2);

      expect(color, const Color(0xFF404040));
    });

    test("keeps the transparency of the color it was given", () {
      final color = ColorsUtility.darkingColor(baseColor: const Color(0x80FF0000), coeff: 2);

      expect(color.a, closeTo(0.5, 0.01));
    });
  });

  group("ColorsUtility.lerpGradient", () {
    const gradient = [(Colors.red, 0.0), (Colors.green, 0.5), (Colors.blue, 1.0)];

    test("picks the color of the stop it lands on", () {
      final color = ColorsUtility.lerpGradient(colorsAndStops: gradient, gradientPercent: 0);

      expect(color, Colors.red);
    });

    test("mixes the two colors surrounding the value", () {
      final color = ColorsUtility.lerpGradient(colorsAndStops: gradient, gradientPercent: 0.25);

      expect(
        color,
        HSVColor.lerp(
          HSVColor.fromColor(Colors.red),
          HSVColor.fromColor(Colors.green),
          0.5,
        )?.toColor(),
      );
    });

    test("picks the last color for a value past the last stop", () {
      final color = ColorsUtility.lerpGradient(colorsAndStops: gradient, gradientPercent: 1);

      expect(color, Colors.blue);
    });

    test("picks the first color for a value before the first stop", () {
      const shifted = [(Colors.red, 0.2), (Colors.blue, 0.8)];

      final color = ColorsUtility.lerpGradient(colorsAndStops: shifted, gradientPercent: 0.1);

      expect(color, Colors.red);
    });

    test("picks the last color for a value after the last stop", () {
      const shifted = [(Colors.red, 0.2), (Colors.blue, 0.8)];

      final color = ColorsUtility.lerpGradient(colorsAndStops: shifted, gradientPercent: 0.9);

      expect(color, Colors.blue);
    });

    test("picks the only color of a gradient which has one", () {
      final color = ColorsUtility.lerpGradient(
        colorsAndStops: const [(Colors.red, 0.0)],
        gradientPercent: 0.5,
      );

      expect(color, Colors.red);
    });
  });
}
