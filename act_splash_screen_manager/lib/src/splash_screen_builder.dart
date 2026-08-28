// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:act_splash_screen_manager_mobile/act_splash_screen_manager_mobile.dart';

/// Builder of the splash screen manager of an application, whatever the platform it runs on.
///
/// An application which runs on a single family of platforms is better off depending on the
/// package of that family and registering its builder: it brings what it uses and nothing else.
///
/// Only the mobile applications are supported so far. The other families are added to this builder
/// as their packages join it, and the choice between them is then made here.
class SplashScreenBuilder extends AbsSplashScreenBuilder {
  /// Class constructor
  const SplashScreenBuilder() : super(MobileSplashScreenManager.new);
}
