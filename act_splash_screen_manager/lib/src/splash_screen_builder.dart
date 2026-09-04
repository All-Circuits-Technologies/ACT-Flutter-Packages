// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_splash_screen_manager/src/abs_splash_screen_manager.dart';
import 'package:act_splash_screen_manager/src/platforms/desktop_splash_screen_manager.dart';
import 'package:act_splash_screen_manager/src/platforms/mobile_splash_screen_manager.dart';
import 'package:act_splash_screen_manager/src/platforms/web_splash_screen_manager.dart';
import 'package:flutter/foundation.dart';

/// Builder of the splash screen manager of an application, whatever the platform it runs on.
///
/// The builder depends on the logger manager, so that the messages of the initialization the
/// splash screen covers are already written where the application writes them.
class SplashScreenBuilder extends AbsLifeCycleFactory<AbsSplashScreenManager> {
  /// Class constructor
  const SplashScreenBuilder() : super(_managerForCurrentPlatform);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager];

  /// {@template act_splash_screen_manager.SplashScreenBuilder.managerForPlatform}
  /// Builds the splash screen manager the given platform needs.
  ///
  /// Which manager answers is decided here and nowhere else.
  /// {@endtemplate}
  @visibleForTesting
  static AbsSplashScreenManager managerForPlatform(MixinActPlatforms platform) {
    if (platform.isWeb) {
      return WebSplashScreenManager();
    }

    if (platform.isLinux || platform.isWindows) {
      return DesktopSplashScreenManager();
    }

    // Android and iOS remove their splash screen by themselves, and the platforms which are not
    // supported yet, macOS and Fuchsia, draw none at all: in both cases there is nothing to ask,
    // which is what the manager of the mobile applications does.
    return MobileSplashScreenManager();
  }

  /// {@macro act_splash_screen_manager.SplashScreenBuilder.managerForPlatform}
  ///
  /// The platform is the one the application really runs on, and not the one Flutter draws like:
  /// an application is free to tell Flutter to look like another platform, and that must not
  /// change which runner the splash screen is asked to.
  static AbsSplashScreenManager _managerForCurrentPlatform() =>
      managerForPlatform(ActPlatform.instance);
}
