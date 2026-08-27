// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:act_splash_screen_manager_mobile/src/mobile_splash_screen_manager.dart';

/// Builder of the splash screen manager of the mobile applications.
class MobileSplashScreenBuilder extends AbsSplashScreenBuilder {
  /// Class constructor
  const MobileSplashScreenBuilder() : super(MobileSplashScreenManager.new);
}
