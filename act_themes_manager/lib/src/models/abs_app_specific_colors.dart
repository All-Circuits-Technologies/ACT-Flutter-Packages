// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';

/// This class is used to define the specific colors of the application that are not defined in the
/// color scheme of the theme.
abstract class AbsAppSpecificColors<ExtColors extends AbsAppSpecificColors<ExtColors>>
    extends ThemeExtension<ExtColors> {
  /// Class constructor
  const AbsAppSpecificColors();
}
