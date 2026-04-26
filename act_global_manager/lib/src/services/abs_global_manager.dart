// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_global_manager/src/types/global_manager_state.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The [globalGetIt] function is used to shortcut access to the managers
GetIt globalGetIt() => AbsGlobalManager.instance!.managers;

/// The [appLogger] function is used to shortcut access to the default logger
MixinActLogger appLogger() => AbsGlobalManager.instance!.defaultLogger;

/// The [AbsGlobalManager] is used to store the Application managers
///
/// In the top class, you have to instantiate and set the [AbsGlobalManager]
///  [instance]
///
/// If you want to use the [AbsGlobalManager] in an application with UI, add the
/// MixinUiGlobalManager mixin to your project global manager.
abstract class AbsGlobalManager extends AbsWithLifeCycle {
  /// The global manager instance
  static AbsGlobalManager? _instance;

  /// Getter of the global manager instance
  static AbsGlobalManager? get instance => _instance;

  /// Set the global manager instance, this has to be called by the derived class.
  @protected
  // The getter linked is [instance]
  // ignore: avoid_setters_without_getters
  static set setInstance(AbsGlobalManager globalManager) => _instance = globalManager;

  /// This is the Get it instance used to get managers
  final managers = GetIt.instance;

  /// This is the list of managers registered in the app
  final List<AbsWithLifeCycle> _registeredManagers;

  /// This returns true if the app is in release mode
  final isReleaseMode = kReleaseMode;

  /// This is the default logger to use in the app
  final MixinActLogger defaultLogger;

  /// This is the list of states of the global manager
  late final List<Enum> _globalManagerStates;

  /// This is the current state of the global manager
  Enum _currentState = GlobalManagerState.notCreated;

  /// The information contained in the pubspec.yaml of the mobile application
  late PackageInfo _packageInfo;

  /// Get the app package info
  PackageInfo get packageInfo => _packageInfo;

  /// This is the list of managers registered in the app
  @protected
  List<AbsWithLifeCycle> get registeredManagers => _registeredManagers;

  /// {@template act_global_manager.AbsGlobalManager.create}
  /// The create constructor is used to construct the singleton instance
  /// {@endtemplate}
  AbsGlobalManager.create({LogsLevel defaultMinLevel = LogsLevel.warn})
      : _currentState = GlobalManagerState.created,
        defaultLogger = LoggerManager.getSafeLogger(
          defaultMinLevel: defaultMinLevel,
        ),
        _registeredManagers = [];

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _globalManagerStates = getGlobalManagerStates();

    if (!tryAdvanceToState(GlobalManagerState.startInit)) {
      return;
    }

    await registerManagers();

    await managers.allReady();

    // Add here what's to be called after that all managers have been loaded
    // and before the views are loaded and displayed
    _packageInfo = await PackageInfo.fromPlatform();

    tryAdvanceToState(GlobalManagerState.allReady);
  }

  /// {@template act_global_manager.AbsGlobalManager.registerManagers}
  /// The [registerManagers] function is called in the [initLifeCycle] method and is used to
  /// register the app managers.
  /// {@endtemplate}
  @protected
  Future<void> registerManagers();

  /// {@template act_global_manager.AbsGlobalManager.getGlobalManagerStates}
  /// Get the list of states of the global manager.
  /// {@endtemplate}
  @protected
  List<Enum> getGlobalManagerStates() => GlobalManagerState.values;

  /// {@template act_global_manager.AbsGlobalManager.registerManagerAsync}
  /// This method is used to register asynchronously the app managers
  /// {@endtemplate}
  @protected
  void registerManagerAsync<T extends AbsWithLifeCycle>(AbsLifeCycleFactory<T> builder) {
    Future<T> asyncFactory() async {
      final manager = await builder.asyncFactory();
      _registeredManagers.add(manager);

      return manager;
    }

    managers.registerSingletonAsync<T>(
      asyncFactory,
      dependsOn: builder.dependsOn(),
    );
  }

  /// {@template act_global_manager.AbsGlobalManager.manageAndVerifyState}
  /// The method verifies if the state is already reached.
  ///
  /// If the state is already reached, it returns false, otherwise it updates the state and returns
  /// true.
  /// {@endtemplate}
  @protected
  bool tryAdvanceToState(Enum state) {
    final stateIndex = _globalManagerStates.indexOf(state);

    if (stateIndex == -1) {
      defaultLogger.e("The state $state is not in the list of global manager states, it will be "
          "considered as already reached");
      return false;
    }

    final currentIndex = _globalManagerStates.indexOf(_currentState);
    if (currentIndex >= stateIndex) {
      // The state is already reached
      return false;
    }

    _currentState = state;
    return true;
  }

  /// {@template act_global_manager.AbsGlobalManager.disposeLifeCycle}
  /// The [disposeLifeCycle] method is used to dispose all the managers
  /// It has to be called in the main app dispose method
  /// {@endtemplate}
  @override
  Future<void> disposeLifeCycle() async {
    defaultLogger.i("Disposing the global manager and managers");
    await Future.wait(_registeredManagers.map((manager) => manager.disposeLifeCycle()));

    await super.disposeLifeCycle();
  }
}
