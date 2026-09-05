// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_global_manager/src/errors/act_manager_already_created_error.dart';
import 'package:act_global_manager/src/errors/act_manager_registering_dead_loop_error.dart';
import 'package:act_global_manager/src/models/manager_extra_info.dart';
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

  /// The registration information of every manager, keyed by its type and kept in the order the
  /// application registered them.
  ///
  /// A manager is recorded here as soon as [registerManagerAsync] is called, before its dependency
  /// order is known: its [ManagerExtraInfo.registrationOrder] and
  /// [ManagerExtraInfo.registeredManager] are filled in later, once the dependencies have been
  /// resolved and the manager has been built.
  final Map<Type, ManagerExtraInfo> _managersInfo;

  /// This returns true if the app is in release mode
  final isReleaseMode = kReleaseMode;

  /// This is the default logger to use in the app
  final MixinActLogger defaultLogger;

  /// This is the list of states of the global manager
  ///
  /// The list is filled by the constructor, which asks the derived class for it.
  late final List<Enum> _globalManagerStates;

  /// This is the current state of the global manager
  Enum _currentState = GlobalManagerState.notCreated;

  /// The information contained in the pubspec.yaml of the mobile application
  late PackageInfo _packageInfo;

  /// Get the app package info
  PackageInfo get packageInfo => _packageInfo;

  /// This is the list of managers registered in the app
  @protected
  List<AbsWithLifeCycle> get registeredManagers => _managersInfo.values
      .where((element) => element.registeredManager != null)
      .map((e) => e.registeredManager!)
      .toList();

  /// {@template act_global_manager.AbsGlobalManager.create}
  /// The create constructor is used to construct the singleton instance
  /// {@endtemplate}
  AbsGlobalManager.create({LogsLevel defaultMinLevel = LogsLevel.warn})
    : _currentState = GlobalManagerState.created,
      defaultLogger = LoggerManager.getSafeLogger(defaultMinLevel: defaultMinLevel),
      _managersInfo = {} {
    _globalManagerStates = getGlobalManagerStates();
  }

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    if (!tryAdvanceToState(GlobalManagerState.startInit)) {
      return;
    }

    await registerManagers();

    _registerAllManagers();

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
    final managerType = T;
    if (_managersInfo.containsKey(managerType)) {
      ActManagerAlreadyCreatedError.crash(managerType: managerType);
    }

    final dependencies = builder.dependsOn();

    ManagerExtraInfo? managerExtraInfo;
    void registerManager(int order) {
      Future<T> asyncFactory() async {
        final manager = await builder.asyncFactory();
        managerExtraInfo!.registeredManager = manager;

        return manager;
      }

      managerExtraInfo!.registrationOrder = order;
      managers.registerSingletonAsync<T>(asyncFactory, dependsOn: dependencies);
    }

    managerExtraInfo = ManagerExtraInfo.init(
      managerType: managerType,
      dependencies: dependencies.toList(),
      register: registerManager,
    );

    _managersInfo[managerType] = managerExtraInfo;
  }

  /// {@template act_global_manager.AbsGlobalManager.manageAndVerifyState}
  /// The method verifies if the state is already reached.
  ///
  /// If the state is already reached, it returns false, otherwise it updates the state and returns
  /// true.
  /// {@endtemplate}
  @protected
  bool tryAdvanceToState(Enum state) {
    if (isStateReached(state)) {
      return false;
    }

    _currentState = state;
    return true;
  }

  /// {@template act_global_manager.AbsGlobalManager.isStateReached}
  /// Checks if the given state has already been reached.
  /// {@endtemplate}
  @protected
  bool isStateReached(Enum state) {
    final stateIndex = _globalManagerStates.indexOf(state);

    if (stateIndex == -1) {
      defaultLogger.e(
        "The state $state is not in the list of global manager states, it will be "
        "considered as already reached",
      );
      return true;
    }

    final currentIndex = _globalManagerStates.indexOf(_currentState);
    return currentIndex >= stateIndex;
  }

  /// Calls [method] on every registered manager, one dependency level at a time.
  ///
  /// The managers are visited following the order their dependencies were resolved: a manager is
  /// only reached once every manager it depends on has been reached. Managers that share a level
  /// have no dependency between them, so [method] is started on all of them at once and awaited
  /// together before moving on to the next level.
  ///
  /// When [isFollowingOrder] is true the levels are walked from the first (the managers without
  /// dependencies) to the last; when it is false they are walked in reverse, which is what disposal
  /// needs so that a manager is torn down before the ones it depends on.
  ///
  /// [condition] restricts the call to the managers it accepts; a manager which has not been built
  /// yet is never offered to it and never called.
  @protected
  Future<void> callMethodFollowingOrder({
    required Future<void> Function(AbsWithLifeCycle manager) method,
    bool Function(AbsWithLifeCycle manager)? condition,
    bool isFollowingOrder = true,
  }) async {
    final toCallEntries = _managersInfo.entries.where((entry) {
      final manager = entry.value.registeredManager;
      if (manager == null) {
        return false;
      }

      return condition == null || condition(manager);
    }).toList();

    // A built manager always has its registration order set (the order is assigned before the
    // manager is built), so the order read here and below is never null.
    var order = 0;
    if (!isFollowingOrder) {
      for (final entry in toCallEntries) {
        final registrationOrder = entry.value.registrationOrder!;
        if (registrationOrder > order) {
          order = registrationOrder;
        }
      }
    }

    while (toCallEntries.isNotEmpty) {
      final toWait = <Future<void>>[];
      final toRemoveEntries = <MapEntry<Type, ManagerExtraInfo>>[];

      for (final entry in toCallEntries) {
        if (entry.value.registrationOrder != order) {
          // Not this manager's level yet.
          continue;
        }

        toWait.add(method(entry.value.registeredManager!));
        toRemoveEntries.add(entry);
      }

      for (final toRemove in toRemoveEntries) {
        toCallEntries.remove(toRemove);
      }

      order += isFollowingOrder ? 1 : -1;

      await Future.wait(toWait);
    }
  }

  /// Registers every manager collected by [registerManagerAsync] into the service locator in an
  /// order which satisfies their dependencies, so that the order the application registered them in
  /// does not matter.
  void _registerAllManagers() => _registerManagers(
    registeredTypes: const [],
    toRegister: _managersInfo.keys.toList(),
    order: 0,
  );

  /// Registers the managers whose dependencies are all met, then recurses on the ones left.
  ///
  /// This is a level-by-level topological resolution: [registeredTypes] holds the managers already
  /// placed, [toRegister] the ones still to place, and [order] the level being filled. Every
  /// manager in [toRegister] whose dependencies are all in [registeredTypes] is registered at
  /// [order]; the others wait for a later level. The recursion stops once every manager has been
  /// placed.
  ///
  /// A pass which places no manager means the ones left either depend on each other (a cycle) or on
  /// a manager which was never registered; both are unrecoverable and raise an
  /// [ActManagerRegisteringDeadLoopError].
  void _registerManagers({
    required List<Type> registeredTypes,
    required List<Type> toRegister,
    required int order,
  }) {
    final tmpToRegister = List<Type>.from(toRegister);
    final tmpRegisteredTypes = List<Type>.from(registeredTypes);

    for (final managerType in toRegister) {
      final managerExtraInfo = _managersInfo[managerType]!;

      final isOk = ListUtility.testIfListIsInList(managerExtraInfo.dependencies, registeredTypes);
      if (!isOk) {
        continue; // Skip this manager as its dependencies are not yet registered
      }

      tmpRegisteredTypes.add(managerType);
      tmpToRegister.remove(managerType);

      managerExtraInfo.register(order);
    }

    if (tmpToRegister.isEmpty) {
      // Nothing more to register
      return;
    }

    if (tmpToRegister.length == toRegister.length) {
      // No progress was made in this iteration, indicating a circular dependency or missing
      // dependencies
      ActManagerRegisteringDeadLoopError.crash(involvedManagers: tmpToRegister);
    }

    return _registerManagers(
      registeredTypes: tmpRegisteredTypes,
      toRegister: tmpToRegister,
      order: order + 1,
    );
  }

  /// {@template act_global_manager.AbsGlobalManager.disposeLifeCycle}
  /// The [disposeLifeCycle] method is used to dispose all the managers
  /// It has to be called in the main app dispose method
  /// {@endtemplate}
  @override
  Future<void> disposeLifeCycle() async {
    defaultLogger.i("Disposing the global manager and managers");
    await callMethodFollowingOrder(
      method: (manager) async => manager.disposeLifeCycle(),
      isFollowingOrder: false,
    );

    await super.disposeLifeCycle();
  }
}
