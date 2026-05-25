// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_themes_manager/src/models/abs_app_specific_colors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// This class is used to define the colors of the theme of the application. It contains the color
/// scheme of the theme and the specific colors of the application that are not defined in the color
/// scheme
class ActThemeColors<ExtColors extends AbsAppSpecificColors<ExtColors>> extends Equatable {
  /// The color scheme of the theme
  final ColorScheme colorScheme;

  /// The specific colors of the application that are not defined in the color scheme
  final ExtColors? colorExtensions;

  /// Class constructor
  const ActThemeColors({required this.colorScheme, this.colorExtensions});

  /// Class properties
  @override
  List<Object?> get props => [colorScheme, colorExtensions];
}
