// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/services.dart';

/// This represents the screen orientation option and say how the may be displayed.
enum ScreenOrientationOption {
  portrayOnly(orientations: [
    DeviceOrientation.portraitUp,
  ]),
  landscapeOnly(orientations: [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]),
  mayRotate(orientations: [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  /// This is the list of [DeviceOrientation] linked to the [ScreenOrientationOption]
  final List<DeviceOrientation> orientations;

  /// Class constructor
  const ScreenOrientationOption({
    required this.orientations,
  });
}
