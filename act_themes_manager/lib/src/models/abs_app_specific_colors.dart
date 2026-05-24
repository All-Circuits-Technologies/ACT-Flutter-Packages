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

  /// {@template act_flutter_utility.AbsAppSpecificColors.getDisabledColor}
  /// This method is used to get a disabled color from a given color. It returns the same color with
  /// an alpha of 102 (40% opacity) to make it look disabled.
  /// {@endtemplate}
  ///
  /// If you want to use a different alpha value, you can override this method in the subclass.
  Color getDisabledColor(Color color) => color.withAlpha(102);
}
