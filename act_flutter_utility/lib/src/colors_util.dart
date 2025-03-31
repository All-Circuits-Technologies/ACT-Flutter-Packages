// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math';

import 'package:flutter/material.dart';

/// Helper class which contains Color utility methods
class ColorsUtil {
  static const int _thresholdRgb = 0xFF;

  /// This method allows to lighting colors.
  ///
  /// The method will make the given [baseColor] lighter, to do so, give a
  /// [coeff] value.
  /// The method will try to keep color and have a tone shade
  static Color lightingColor({
    required Color baseColor,
    required double coeff,
  }) =>
      _redistributeRgb(
          redWithCoef: baseColor.r * coeff,
          greenWithCoef: baseColor.g * coeff,
          blueWithCoef: baseColor.b * coeff,
          alpha: baseColor.a);

  /// This method allows to make colors darker.
  ///
  /// The method will make the given [baseColor] darker, to do so, give a
  /// [coeff] value.
  /// The method will try to keep color and have a tone shade
  static Color darkingColor({
    required Color baseColor,
    required double coeff,
  }) =>
      _redistributeRgb(
        redWithCoef: baseColor.r / coeff,
        greenWithCoef: baseColor.g / coeff,
        blueWithCoef: baseColor.b / coeff,
        alpha: baseColor.a,
      );

  /// This method picks a color from a gradient thanks to the [gradientPercent] given.
  ///
  /// The argument [colorsAndStops] contains the description of the gradient, the first element is
  /// the color and the second the stop from which the gradient starts.
  ///
  /// If the stop of the first element is greater than 0, all the values before use the first color
  /// If the stop of the last element is lesser than 1, all the values after use the last color
  static Color? lerpGradient({
    required List<(Color, double)> colorsAndStops,
    required double gradientPercent,
  }) {
    for (var idx = 0; idx < colorsAndStops.length - 1; idx++) {
      final (leftColor, leftStop) = colorsAndStops[idx];
      final (rightColor, rightStop) = colorsAndStops[idx + 1];

      if (gradientPercent <= leftStop) {
        return leftColor;
      }

      if (gradientPercent < rightStop) {
        final sectionT = (gradientPercent - leftStop) / (rightStop - leftStop);

        // Use HSV to have better color interpolation
        return HSVColor.lerp(
          HSVColor.fromColor(leftColor),
          HSVColor.fromColor(rightColor),
          sectionT,
        )?.toColor();
      }
    }

    return colorsAndStops.last.$1;
  }

  /// This method retry to manage the bounds in order to keep a tone shade until
  /// the last color: black or white
  ///
  /// The [redWithCoef], [greenWithCoef] and [blueWithCoef] are values which can
  /// overflow the 0xFF limit.
  /// The [alpha] given is the current alpha of the color given, the new color
  /// will have the same
  static Color _redistributeRgb({
    required double redWithCoef,
    required double greenWithCoef,
    required double blueWithCoef,
    required double alpha,
  }) {
    double maxValue = max(redWithCoef, greenWithCoef);
    maxValue = max(maxValue, blueWithCoef);
    final alphaRounded = alpha.round();

    if (maxValue <= _thresholdRgb) {
      return Color.fromARGB(
        alphaRounded,
        redWithCoef.round(),
        greenWithCoef.round(),
        blueWithCoef.round(),
      );
    }

    final totalValue = redWithCoef + greenWithCoef + blueWithCoef;

    if (totalValue >= (3 * _thresholdRgb)) {
      return Color.fromARGB(alphaRounded, _thresholdRgb, _thresholdRgb, _thresholdRgb);
    }

    final toneCoeff = ((3 * _thresholdRgb) - totalValue) / ((3 * maxValue) - totalValue);

    final gray = _thresholdRgb - (toneCoeff * maxValue);

    return Color.fromARGB(
      alphaRounded,
      _toneAColor(color: redWithCoef, toneCoeff: toneCoeff, gray: gray),
      _toneAColor(color: greenWithCoef, toneCoeff: toneCoeff, gray: gray),
      _toneAColor(color: blueWithCoef, toneCoeff: toneCoeff, gray: gray),
    );
  }

  /// This method allows to give the right color layer with the [toneCoeff] and
  /// [gray] value given.
  static int _toneAColor({
    required double color,
    required double toneCoeff,
    required double gray,
  }) =>
      (gray + (toneCoeff * color)).round();
}
