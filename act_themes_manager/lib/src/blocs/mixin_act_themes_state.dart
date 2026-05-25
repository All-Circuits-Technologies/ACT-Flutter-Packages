// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_themes_manager/src/types/mixin_act_themes.dart';
import 'package:flutter/material.dart' show Brightness, ThemeMode;

/// This mixin is used for the main app state, to get the current theme of the application
mixin MixinActThemesState<S extends MixinActThemesState<S>> on BlocStateForMixin<S> {
  /// {@template act_themes_manager.MixinActThemesState.currentTheme}
  /// The current theme of the application.
  /// {@endtemplate}
  MixinActThemes get currentTheme;

  /// {@template act_themes_manager.MixinActThemesState.brightness}
  /// The current brightness mode of the application.
  ///
  /// If null, we will use the system default brightness mode.
  /// {@endtemplate}
  Brightness? get brightness;

  /// This is a helper getter to get the current theme mode of the application based on the
  /// brightness value.
  ThemeMode get themeMode => switch (brightness) {
    Brightness.light => ThemeMode.light,
    Brightness.dark => ThemeMode.dark,
    null => ThemeMode.system,
  };

  /// {@template act_themes_manager.MixinActThemesState.copyActThemesState}
  /// This is the copyWith method for the mixin
  /// {@endtemplate}
  S copyActThemesState({
    MixinActThemes? currentTheme,
    Brightness? brightness,
    bool forceBrightnessValue = false,
  });

  /// This method is used to copy the state with a new theme
  S copyToNewThemeState({required MixinActThemes currentTheme}) =>
      copyActThemesState(currentTheme: currentTheme);

  /// This method is used to copy the state with a new brightness value
  S copyToNewBrightnessState({required Brightness? brightness}) =>
      copyActThemesState(brightness: brightness, forceBrightnessValue: true);

  /// {@macro act_flutter_utility.BlocStateForMixin.props}
  @override
  List<Object?> get props => [...super.props, currentTheme, brightness];
}
