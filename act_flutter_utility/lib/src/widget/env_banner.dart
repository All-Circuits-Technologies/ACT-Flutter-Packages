// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// This class is useful to add banner with the current environment used for the app.
///
/// The banner is displayed at the top start of the the app bar (to not hide widgets in the bottom).
///
/// The production banner is only displayed when the app is in debug.
class EnvBanner extends Banner {
  /// This is the color used for the banner when we are in the development environment
  static const Color _devColor = Colors.red;

  /// This is the color used for the banner when we are in the qualification environment
  static const Color _qualColor = Colors.blue;

  /// This is the color used for the banner when we are in the production environment
  static const Color _prodColor = Colors.green;

  /// This is the default color used for the banner
  static const Color _defaultColor = Color(0xA0B71C1C);

  /// Class constructor
  const EnvBanner._({
    required super.message,
    required super.color,
    required Widget super.child,
  }) : super(location: BannerLocation.topStart);

  /// Build and display a Banner above the child if its needed.
  ///
  /// If the banner isn't needed, the child is directly returned
  static Widget displayAppBarBanner<ConfigManager extends AbstractConfigManager>({
    required Widget child,
  }) {
    final configManager = globalGetIt().get<ConfigManager>();

    final shortTxt = configManager.env.parsedString;

    if (kReleaseMode && configManager.env == Environment.production || shortTxt == null) {
      // Nothing to do
      return child;
    }

    return EnvBanner._(
      message: shortTxt,
      color: _getColor(configManager.env),
      child: child,
    );
  }

  /// Get the color linked to the given [env]
  static Color _getColor(Environment env) => switch (env) {
        Environment.production => _prodColor,
        Environment.development => _devColor,
        Environment.qualification => _qualColor,
        _ => _defaultColor,
      };
}
