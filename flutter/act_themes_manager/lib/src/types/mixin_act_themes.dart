// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_themes_manager/src/models/act_theme_model.dart';

/// This mixin is used to list the themes of the application.
mixin MixinActThemes on MixinStringValueType {
  /// {@template act_themes_manager.MixinActThemes.themeData}
  /// The theme data of the theme.
  /// {@endtemplate}
  ActThemeModel get themeData;
}
