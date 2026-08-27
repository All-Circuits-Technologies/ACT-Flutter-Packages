// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Splash screen manager of the desktop applications.
///
/// The splash screen of a desktop application is drawn by its runner, in the window of the
/// application and before the engine is started, and the runner keeps drawing it until it is asked
/// to stop. The manager asks it once the application is ready.
class DesktopSplashScreenManager extends AbsSplashScreenManager {
  /// Category the messages of the manager are logged under.
  static const _logsCategory = "splashScreen";

  /// Channel the runner of the application is reached through.
  @visibleForTesting
  static const channel = MethodChannel("act_splash_screen");

  /// Logger given to the manager, null when it logs where the application logs.
  final MixinActLogger? _givenLogger;

  /// Logger of the manager
  late final MixinActLogger _logger;

  /// Class constructor
  ///
  /// A logger is only given by a test which asserts on what the manager says.
  DesktopSplashScreenManager({MixinActLogger? logger}) : _givenLogger = logger;

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _logger = _givenLogger ?? LogsHelper(category: _logsCategory);
  }

  /// {@macro act_splash_screen_manager_core.AbsSplashScreenManager.hideNativeSplashScreen}
  @override
  Future<void> hideNativeSplashScreen() async {
    try {
      await channel.invokeMethod<void>("hide");
    } on MissingPluginException {
      // The runner of the application draws no splash screen: there is nothing to remove, and the
      // application has to start anyway.
      _logger.w("The runner of the application draws no splash screen to remove");
    }
  }
}
