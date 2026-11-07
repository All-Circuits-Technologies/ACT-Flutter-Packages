// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';

/// Drive the life cycle of an application under test from the test.
///
/// A real manager reads the life cycle from the binding of the application; this one is told when
/// the application is left and when it comes back.
class FakeAppLifeCycleManager extends AppLifeCycleManager {
  /// Send the life cycle of the application to the listeners.
  final StreamController<AppLifecycleState?> _ctrl;

  /// {@macro act_app_life_cycle_manager.AppLifeCycleManager.lifeCycleStream}
  @override
  Stream<AppLifecycleState?> get lifeCycleStream => _ctrl.stream;

  /// Create the manager, which doesn't tell anything until the test does.
  FakeAppLifeCycleManager() : _ctrl = StreamController<AppLifecycleState?>.broadcast();

  /// Tell the application that it is now in [state].
  Future<void> goTo(AppLifecycleState state) async {
    _ctrl.add(state);

    return Future.delayed(Duration.zero);
  }

  /// {@macro act_app_life_cycle_manager.AppLifeCycleManager.waitForegroundApp}
  ///
  /// The application is told that it was left and that it came back, which is what a real manager
  /// waits for and what has the permissions read again.
  @override
  Future<void> waitForegroundApp({required Future<bool> Function() leaveTheApp}) async {
    await goTo(AppLifecycleState.paused);
    await leaveTheApp();
    await goTo(AppLifecycleState.resumed);
  }

  /// Stop telling the application about its life cycle.
  Future<void> close() => _ctrl.close();
}
