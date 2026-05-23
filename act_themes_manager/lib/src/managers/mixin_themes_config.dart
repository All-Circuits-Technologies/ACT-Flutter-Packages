// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_themes_manager/src/types/mixin_act_themes.dart';

/// This mixin is used to define the configuration of the themes manager.
mixin MixinThemesConfig on AbstractConfigManager {
  /// This is the config variable that defines the default theme of the application, it should be
  /// match the name of one of the themes defined in the [MixinActThemes] mixin.
  ///
  /// If this is null or does not match any of the themes defined in the [MixinActThemes] mixin, the
  /// first theme defined in the [MixinActThemes] mixin will be used as the default theme.
  ///
  /// The default value is only used if there is no theme saved in the local storage.
  final defaultTheme = const ConfigVar<String>("themes.default");

  /// This is the config variable used to force the theme of the application in development mode.
  ///
  /// If true, it means that, in dev only, we use the [defaultTheme] even if there is a theme saved
  /// in the local storage. This is useful to force a specific theme in development mode, without
  /// having to clear the local storage each time we want to change the default theme.
  ///
  /// This has no effet if the [defaultTheme] is not defined or does not match any of the themes
  /// defined in the [MixinActThemes] mixin.
  final forceThemeInDev = const NotNullableConfigVar<bool>("themes.dev.force", defaultValue: false);

  /// This is the config variable used to force the brightness mode of the application in
  /// development mode.
  ///
  /// If true, it means that, in dev only, we use the brightness light even if there is a value
  /// saved in the local storage.
  /// If false, it means that, in dev only, we use the brightness dark even if there is a value
  /// saved in the local storage.
  ///
  /// If null, it means that we use the system default brightness or the value saved in the local
  /// storage if there is one.
  final forceLightModeInDevValue = const ConfigVar<bool>("themes.dev.forceLightModeValue");
}
