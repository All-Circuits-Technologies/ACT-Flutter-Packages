// Copyright (c) 2020. BMS Circuits

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Helper class which contains Color utility methods
class ColorsUtil {
  static int _thresholdRgb = 0xFF;

  /// This method allows to lighting colors.
  ///
  /// The method will make the given [baseColor] lighter, to do so, give a
  /// [coeff] value.
  /// The method will try to keep color and have a tone shade
  static Color lightingColor(Color baseColor, double coeff) {
    return _redistributeRgb(baseColor.red * coeff, baseColor.green * coeff,
        baseColor.blue * coeff, baseColor.alpha);
  }

  /// This method allows to make colors darker.
  ///
  /// The method will make the given [baseColor] darker, to do so, give a
  /// [coeff] value.
  /// The method will try to keep color and have a tone shade
  static Color darkingColor(Color baseColor, double coeff) {
    return _redistributeRgb(baseColor.red / coeff, baseColor.green / coeff,
        baseColor.blue / coeff, baseColor.alpha);
  }

  /// This method retry to manage the bounds in order to keep a tone shade until
  /// the last color: black or white
  ///
  /// The [redWithCoef], [greenWithCoef] and [blueWithCoef] are values which can
  /// overflow the 0xFF limit.
  /// The [alpha] given is the current alpha of the color given, the new color
  /// will have the same
  static Color _redistributeRgb(double redWithCoef, double greenWithCoef,
      double blueWithCoef, int alpha) {
    double maxValue = max(redWithCoef, greenWithCoef);
    maxValue = max(maxValue, blueWithCoef);

    if (maxValue <= _thresholdRgb) {
      return Color.fromARGB(alpha, redWithCoef.round(), greenWithCoef.round(),
          blueWithCoef.round());
    }

    double totalValue = redWithCoef + greenWithCoef + blueWithCoef;

    if (totalValue >= (3 * _thresholdRgb)) {
      return Color.fromARGB(alpha, _thresholdRgb, _thresholdRgb, _thresholdRgb);
    }

    double toneCoeff =
        ((3 * _thresholdRgb) - totalValue) / ((3 * maxValue) - totalValue);

    double gray = _thresholdRgb - (toneCoeff * maxValue);

    return Color.fromARGB(
      alpha,
      _toneAColor(redWithCoef, toneCoeff, gray),
      _toneAColor(greenWithCoef, toneCoeff, gray),
      _toneAColor(blueWithCoef, toneCoeff, gray),
    );
  }

  /// This method allows to give the right color layer with the [toneCoef] and
  /// [gray] value given.
  static int _toneAColor(double color, double toneCoeff, double gray) {
    return (gray + (toneCoeff * color)).round();
  }
}
