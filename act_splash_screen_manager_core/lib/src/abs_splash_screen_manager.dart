// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter/widgets.dart';

/// Base of the managers which keep the splash screen of the platform displayed until the first
/// view of the application is built.
///
/// The splash screen the platform displays is removed as soon as Flutter is ready, which is before
/// the managers of the application are. Without this manager, the application shows an empty
/// screen during that time; with it, the splash screen covers the whole initialization.
///
/// The manager holds the first frame back while the managers are initialized, then lets the frames
/// through and asks the platform to remove its splash screen. Which platforms have to be asked,
/// and how, is what the derived classes bring.
abstract class AbsSplashScreenManager extends AbsWithLifeCycleAndUi {
  /// Binding the first frame is held back on, null when nothing is held back.
  WidgetsBinding? _widgetsBinding;

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    // The frames are held back, which leaves the splash screen of the platform on the screen.
    _widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    _widgetsBinding!.deferFirstFrame();
  }

  /// {@macro act_life_cycle.MixinUiLifeCycle.initAfterView}
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    // The initialization is over: the frames are let through and the splash screen is removed.
    _widgetsBinding?.allowFirstFrame();
    _widgetsBinding = null;

    await hideNativeSplashScreen();
  }

  /// {@template act_splash_screen_manager_core.AbsSplashScreenManager.hideNativeSplashScreen}
  /// Removes the splash screen drawn by the platform.
  ///
  /// Some platforms remove it by themselves as soon as the first frame is rendered, and the method
  /// has nothing to do for them; the others have to be asked for it.
  /// {@endtemplate}
  @protected
  Future<void> hideNativeSplashScreen();
}
