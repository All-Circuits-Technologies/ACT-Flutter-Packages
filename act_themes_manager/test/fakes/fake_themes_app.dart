// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_themes_manager/act_themes_manager.dart';
import 'package:flutter/material.dart';

/// The colors an application adds to the ones of a color scheme.
class FakeSpecificColors extends AbsAppSpecificColors<FakeSpecificColors> {
  /// The color the application paints what it wants to draw attention to.
  final Color highlight;

  /// Class constructor
  const FakeSpecificColors({required this.highlight});

  /// {@macro flutter.widgets.ThemeExtension.copyWith}
  @override
  FakeSpecificColors copyWith({Color? highlight}) =>
      FakeSpecificColors(highlight: highlight ?? this.highlight);

  /// {@macro flutter.widgets.ThemeExtension.lerp}
  @override
  FakeSpecificColors lerp(FakeSpecificColors? other, double t) =>
      other == null ? this : FakeSpecificColors(highlight: other.highlight);
}

/// The themes of the application under test.
enum FakeThemes with MixinStringValueType, MixinActThemes {
  /// The theme the application starts with.
  blue,

  /// The other theme the user can choose.
  green;

  /// {@macro act_themes_manager.MixinActThemes.themeData}
  @override
  ActThemeModel get themeData => ActThemeModel<FakeSpecificColors>(
    lightColors: ActThemeColors<FakeSpecificColors>(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      colorExtensions: const FakeSpecificColors(highlight: Colors.amber),
    ),
    darkColors: ActThemeColors<FakeSpecificColors>(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
    ),
  );
}

/// The configuration of the application under test.
///
/// A real configuration reads its environment from the value the application was built with, and
/// a test cannot build itself twice. This one takes the environment as an argument and drops the
/// one the build gives it.
class FakeThemesConfig extends AbstractConfigManager with MixinThemesConfig {
  /// The environment the test wants the application to run in.
  final Environment _env;

  @override
  Environment get env => _env;

  @override
  set env(Environment value) {
    // The environment of the build is dropped: the test decides which one the application runs in.
  }

  /// Class constructor
  FakeThemesConfig({Environment env = Environment.development})
    : _env = env,
      super(logger: const SilentLogger());
}

/// The properties of the application under test.
class FakeThemesProperties extends AbstractPropertiesManager with MixinThemesProperties {}

/// The state of the page of the application under test.
class FakeThemesState extends BlocStateForMixin<FakeThemesState>
    with MixinActThemesState<FakeThemesState> {
  /// {@macro act_themes_manager.MixinActThemesState.currentTheme}
  @override
  final MixinActThemes currentTheme;

  /// {@macro act_themes_manager.MixinActThemesState.brightness}
  @override
  final Brightness? brightness;

  /// Class constructor
  const FakeThemesState({required this.currentTheme, this.brightness});

  /// {@macro act_flutter_utility.BlocStateForMixin.copyWith}
  @override
  FakeThemesState copyWith() => this;

  /// {@macro act_themes_manager.MixinActThemesState.copyActThemesState}
  @override
  FakeThemesState copyActThemesState({
    MixinActThemes? currentTheme,
    Brightness? brightness,
    bool forceBrightnessValue = false,
  }) => FakeThemesState(
    currentTheme: currentTheme ?? this.currentTheme,
    brightness: brightness ?? (forceBrightnessValue ? null : this.brightness),
  );
}

/// The bloc of the page of the application under test.
class FakeThemesBloc extends BlocForMixin<FakeThemesState>
    with MixinActThemesBloc<ActThemesManager, FakeThemesState> {
  /// Class constructor
  FakeThemesBloc(super.initialState);
}
