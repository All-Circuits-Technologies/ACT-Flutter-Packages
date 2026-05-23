// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'abs_app_specific_colors.dart';
import 'act_theme_colors.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// This class is used to define the theme of the application. It contains the theme data of the
/// light and dark themes of the application. At least one of the light or dark themes must be
/// defined.
class ActThemeModel<ExtColors extends AbsAppSpecificColors<ExtColors>> extends Equatable {
  /// The theme data of the light theme of the application. It can be null if the light theme is not
  /// defined.
  final ThemeData? lightThemeData;

  /// The theme data of the dark theme of the application. It can be null if the dark theme is not
  /// defined.
  final ThemeData? darkThemeData;

  /// Class factory constructor
  ///
  /// The [lightColors] and [darkColors] parameters are used to define the colors of the light and
  /// dark themes of the application. At least one of them must be defined. If both of them are
  /// defined, they will be used to build the theme data of the light and dark themes of the
  /// application.
  ///
  /// The [fontFamily] parameter is used to define the font family of the themes of the application.
  ///
  /// The [overrideDefaultTextTheme] and [overrideDefaultThemeData] parameters are used to override
  /// the default text theme and theme data of the themes of the application.
  /// They are optional and can be used to customize the themes of the application even more.
  /// If they are not defined, the default text theme and theme data of the themes of the
  /// application will be used.
  ///
  /// The [overrideDefaultTextTheme] is called before the [overrideDefaultThemeData] method and
  /// this last one is called with the theme data updated by the [overrideDefaultTextTheme].
  factory ActThemeModel({
    ActThemeColors<ExtColors>? lightColors,
    ActThemeColors<ExtColors>? darkColors,
    String? fontFamily,
    TextTheme Function({required ThemeData baseThemeData})? overrideDefaultTextTheme,
    ThemeData Function({required ThemeData baseThemeData})? overrideDefaultThemeData,
  }) {
    assert(
      lightColors != null || darkColors != null,
      "At least one of the light or dark colors must be defined",
    );

    final lightThemeData = (lightColors != null)
        ? _buildThemeData(
            colors: lightColors,
            brightness: Brightness.light,
            fontFamily: fontFamily,
            overrideDefaultTextTheme: overrideDefaultTextTheme,
            overrideDefaultThemeData: overrideDefaultThemeData,
          )
        : null;

    final darkThemeData = (darkColors != null)
        ? _buildThemeData(
            colors: darkColors,
            brightness: Brightness.dark,
            fontFamily: fontFamily,
            overrideDefaultTextTheme: overrideDefaultTextTheme,
            overrideDefaultThemeData: overrideDefaultThemeData,
          )
        : null;

    return ActThemeModel._(lightThemeData: lightThemeData, darkThemeData: darkThemeData);
  }

  /// Class private constructor
  const ActThemeModel._({required this.lightThemeData, required this.darkThemeData});

  /// {@template act_flutter_utility.ActThemeModel.getDisabledColor}
  /// This method is used to get a disabled color from a given color. It returns the same color with
  /// an alpha of 102 (40% opacity) to make it look disabled.
  /// {@endtemplate}
  ///
  /// If you want to use a different alpha value, you can override this method in a subclass.
  Color getDisabledColor(Color color) => color.withAlpha(102);

  /// Build the theme data of the application from the [colors] parameter and the
  /// [overrideDefaultTextTheme] and [overrideDefaultThemeData] methods.
  static ThemeData _buildThemeData({
    required ActThemeColors colors,
    required String? fontFamily,
    required Brightness brightness,
    required TextTheme Function({required ThemeData baseThemeData})? overrideDefaultTextTheme,
    required ThemeData Function({required ThemeData baseThemeData})? overrideDefaultThemeData,
  }) {
    var themeData = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors.colorScheme,
      fontFamily: fontFamily,
      extensions: colors.colorExtensions != null ? [colors.colorExtensions!] : null,
    );

    if (overrideDefaultTextTheme != null) {
      themeData = themeData.copyWith(textTheme: overrideDefaultTextTheme(baseThemeData: themeData));
    }

    if (overrideDefaultThemeData != null) {
      themeData = overrideDefaultThemeData(baseThemeData: themeData);
    }

    return themeData;
  }

  /// Class properties
  @override
  List<Object?> get props => [lightThemeData, darkThemeData];
}
