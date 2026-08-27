// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:act_splash_screen_manager_mobile/act_splash_screen_manager_mobile.dart';
import 'package:act_splash_screen_manager_web/act_splash_screen_manager_web.dart';
import 'package:flutter/foundation.dart';

/// Builder of the splash screen manager of an application, whatever the platform it runs on.
///
/// An application which runs on a single family of platforms is better off depending on the
/// package of that family and registering its builder: it brings what it uses and nothing else.
class SplashScreenBuilder extends AbsSplashScreenBuilder {
  /// Class constructor
  const SplashScreenBuilder() : super(_managerForCurrentPlatform);

  /// {@template act_splash_screen_manager.SplashScreenBuilder.managerForPlatform}
  /// Builds the splash screen manager the given platform needs.
  ///
  /// Which package answers is decided here and nowhere else: a package cannot be depended upon by
  /// a platform and ignored by another, so the families are all brought and one is used.
  /// {@endtemplate}
  @visibleForTesting
  static AbsSplashScreenManager managerForPlatform(MixinActPlatforms platform) {
    if (platform.isWeb) {
      return WebSplashScreenManager();
    }

    // Android and iOS remove their splash screen by themselves, and the platforms which are not
    // supported yet draw none at all: in both cases there is nothing to ask, which is what the
    // manager of the mobile applications does.
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
