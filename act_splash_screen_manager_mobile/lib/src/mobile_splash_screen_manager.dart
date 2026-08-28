// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';

/// Splash screen manager of the mobile applications.
///
/// Android, the SplashScreen API of Android 12 and later included, and iOS remove their splash
/// screen by themselves as soon as the first frame is rendered: there is nothing to ask them.
/// Holding the first frame back until the application is ready, which the base class does, is all
/// these platforms need.
class MobileSplashScreenManager extends AbsSplashScreenManager {
  /// {@macro act_splash_screen_manager_core.AbsSplashScreenManager.hideNativeSplashScreen}
  @override
  Future<void> hideNativeSplashScreen() async {
    // Nothing to ask: the platform removes its splash screen by itself.
  }
}
