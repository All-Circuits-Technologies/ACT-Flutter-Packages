// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter/widgets.dart';

/// Builder for creating the LifeCycleManager
class LifeCycleBuilder extends ManagerBuilder<LifeCycleManager> {
  /// Class constructor with the class construction
  LifeCycleBuilder() : super(() => LifeCycleManager());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [];
}

/// Useful manager to know the current application life cycle state
class LifeCycleManager extends AbstractManager {
  late _WidgetsObserver _widgetsObserver;

  /// Get current life cycle state
  AppLifecycleState? get lifeCycleState => _widgetsObserver.lifeCycleState;

  /// Get life cycle stream
  Stream<AppLifecycleState?> get lifeCycleStream =>
      _widgetsObserver.lifeCycleStream;

  LifeCycleManager() : super();

  /// Init manager
  @override
  Future<void> initManager() async {
    _widgetsObserver = _WidgetsObserver();

    WidgetsBinding.instance.addObserver(_widgetsObserver);
  }

  /// This method waits the returns of the app to the resumed step, that means if the app goes never
  /// to background this will never return
  ///
  /// Most of the time, we wait for the app to return to foreground after having open a system page,
  /// use [leaveTheApp] to give the method which makes the app leaves foreground state.
  /// In this way, we detect the app leave and then the app return.
  ///
  /// If [leaveTheApp] returns true, it means that a problem occurred and we don't need to wait
  /// forever.
  Future<void> waitForegroundApp({
    required Future<bool> Function() leaveTheApp,
  }) async {
    // First we wait the app leaving detection
    await WaitUtility.waitForStatus(
      isExpectedStatus: (status) => (status == AppLifecycleState.paused),
      valueGetter: () => _widgetsObserver._lifeCycleState,
      statusEmitter: lifeCycleStream,
      doAction: leaveTheApp,
    );

    // Second we wait the return to the app
    await WaitUtility.waitForStatus(
      isExpectedStatus: (status) => (status == AppLifecycleState.resumed),
      valueGetter: () => _widgetsObserver._lifeCycleState,
      statusEmitter: lifeCycleStream,
    );
  }

  @override
  Future<void> dispose() async {
    await _widgetsObserver.dispose();

    WidgetsBinding.instance.removeObserver(_widgetsObserver);

    await super.dispose();
  }
}

/// Useful class to observe the application life cycle
class _WidgetsObserver extends WidgetsBindingObserver {
  AppLifecycleState? _lifeCycleState;

  final StreamController<AppLifecycleState?> _lifeCycleStreamCtrl;

  /// Application life cycle state
  AppLifecycleState? get lifeCycleState => _lifeCycleState;

  /// Application life cycle stream
  Stream<AppLifecycleState?> get lifeCycleStream => _lifeCycleStreamCtrl.stream;

  /// Class constructor
  _WidgetsObserver()
      : _lifeCycleStreamCtrl = StreamController<AppLifecycleState>.broadcast();

  Future<void> dispose() async => _lifeCycleStreamCtrl.close();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != _lifeCycleState) {
      _lifeCycleState = state;
      if (!_lifeCycleStreamCtrl.isClosed) {
        _lifeCycleStreamCtrl.add(state);
      }
    }
  }
}
