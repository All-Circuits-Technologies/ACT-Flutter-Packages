// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_themes_manager/src/types/mixin_act_themes.dart';
import 'package:flutter/widgets.dart' show Brightness;

/// Emitted when the theme of the application is updated, with the new theme.
class ThemeUpdatedEvent extends BlocEventForMixin {
  /// The updated theme
  final MixinActThemes updatedTheme;

  /// Class constructor
  const ThemeUpdatedEvent({required this.updatedTheme});

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props, updatedTheme];
}

/// Emitted when the brightness of the application is updated.
class BrightnessUpdatedEvent extends BlocEventForMixin {
  /// The updated brightness mode of the application
  final Brightness? brightness;

  /// Class constructor
  const BrightnessUpdatedEvent({required this.brightness});

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props, brightness];
}

/// Emitted when the user wants to update the theme of the application with the new theme.
class AskToUpdateThemeEvent extends BlocEventForMixin {
  /// The new theme to update
  final MixinActThemes newTheme;

  /// Class constructor
  const AskToUpdateThemeEvent({required this.newTheme});

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props, newTheme];
}

/// Emitted when the user wants to update the brightness of the application with the new brightness
/// value.
class AskToUpdateBrightnessEvent extends BlocEventForMixin {
  /// The new brightness value to update
  final Brightness? newBrightness;

  /// Class constructor
  const AskToUpdateBrightnessEvent({required this.newBrightness});

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props, newBrightness];
}
