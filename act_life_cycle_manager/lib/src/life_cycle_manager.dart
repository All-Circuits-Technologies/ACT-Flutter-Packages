// Copyright (c) 2020. BMS Circuits

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
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
  _WidgetsObserver _widgetsObserver;

  /// Get current life cycle state
  AppLifecycleState get lifeCycleState => _widgetsObserver.lifeCycleState;

  /// Get life cycle stream
  Stream<AppLifecycleState> get lifeCycleStream =>
      _widgetsObserver.lifeCycleStream;

  LifeCycleManager() : super();

  /// Init manager
  @override
  Future<void> initManager() async {
    _widgetsObserver = _WidgetsObserver();

    WidgetsBinding.instance.addObserver(_widgetsObserver);
  }

  @override
  Future<void> dispose() async {
    await _widgetsObserver.dispose();

    WidgetsBinding.instance?.removeObserver(_widgetsObserver);
  }
}

/// Useful class to observe the application life cycle
class _WidgetsObserver extends WidgetsBindingObserver {
  AppLifecycleState _lifeCycleState;

  StreamController<AppLifecycleState> _lifeCycleStreamCtrl;

  /// Application life cycle state
  AppLifecycleState get lifeCycleState => _lifeCycleState;

  /// Application life cycle stream
  Stream<AppLifecycleState> get lifeCycleStream => _lifeCycleStreamCtrl.stream;

  /// Class constructor
  _WidgetsObserver() {
    _lifeCycleStreamCtrl = StreamController<AppLifecycleState>.broadcast();
  }

  Future<void> dispose() async {
    return _lifeCycleStreamCtrl.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != _lifeCycleState) {
      _lifeCycleState = state;
      _lifeCycleStreamCtrl.add(state);
    }
  }
}
