// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Builder of the splash screen manager
class SplashScreenBuilder extends ManagerBuilder<SplashScreenManager> {
  /// Class constructor
  SplashScreenBuilder() : super(() => SplashScreenManager());

  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// Splash screen manager
///
/// This manager keeps the splash screen until the first view is built. Therefore, it covers the
/// managers initialization.
class SplashScreenManager extends AbstractManager {
  @override
  Future<void> initManager() async {
    // We keep the splashscreen displaying until all is ready
    FlutterNativeSplash.preserve(
        widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
  }

  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);
    // The initialization is completed, we remove the splashscreen
    FlutterNativeSplash.remove();
  }
}
