// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Splash screen manager of the web applications.
///
/// The splash screen of a web application is drawn by the page which hosts it, and that page keeps
/// drawing it until it is asked to stop. The manager asks it once the application is ready.
class WebSplashScreenManager extends AbsSplashScreenManager {
  /// {@macro act_splash_screen_manager_core.AbsSplashScreenManager.hideNativeSplashScreen}
  @override
  Future<void> hideNativeSplashScreen() async => FlutterNativeSplash.remove();
}
