// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter/widgets.dart';

/// The function a test gives to register the managers of its application.
typedef RegisterManagersFunc<T> = Future<void> Function(T globalManager);

/// A global manager which registers what the test asks it to.
///
/// The manager sets itself as the instance of the application, as the derived class of an
/// application does, so that the shortcuts to the managers and to the logger reach it.
class FakeGlobalManager extends AbsGlobalManager {
  /// Registers the managers of the test, if it has any.
  final RegisterManagersFunc<FakeGlobalManager>? onRegisterManagers;

  /// Class constructor
  FakeGlobalManager({this.onRegisterManagers, super.defaultMinLevel}) : super.create() {
    AbsGlobalManager.setInstance = this;
  }

  /// {@macro act_global_manager.AbsGlobalManager.registerManagers}
  @override
  Future<void> registerManagers() async => onRegisterManagers?.call(this);

  /// {@macro act_global_manager.AbsGlobalManager.registerManagerAsync}
  void register<T extends AbsWithLifeCycle>(AbsLifeCycleFactory<T> builder) =>
      registerManagerAsync<T>(builder);

  /// {@macro act_global_manager.AbsGlobalManager.manageAndVerifyState}
  bool advanceTo(Enum state) => tryAdvanceToState(state);

  /// {@macro act_global_manager.AbsGlobalManager.getGlobalManagerStates}
  List<Enum> get statesOfTheApp => getGlobalManagerStates();

  /// The managers which have been registered and initialized.
  List<AbsWithLifeCycle> get managersOfTheApp => registeredManagers;
}

/// A global manager of an application with a UI, which registers what the test asks it to.
class FakeUiGlobalManager extends AbsUiGlobalManager {
  /// Registers the managers of the test, if it has any.
  final RegisterManagersFunc<FakeUiGlobalManager>? onRegisterManagers;

  /// The page displayed when the initialization of the managers fails.
  ///
  /// When null, no fatal error manager is registered, so the error is rethrown and no page is
  /// displayed.
  final Widget? fatalErrorPage;

  /// Class constructor
  FakeUiGlobalManager({this.onRegisterManagers, this.fatalErrorPage, super.defaultMinLevel})
    : super.create() {
    AbsGlobalManager.setInstance = this;
  }

  /// {@macro act_global_manager.AbsGlobalManager.registerManagers}
  @override
  Future<void> registerManagers() async {
    if (fatalErrorPage != null) {
      register<UiFatalErrorManager>(UiFatalErrorBuilder((_) => fatalErrorPage!));
    }

    await onRegisterManagers?.call(this);
  }

  /// {@macro act_global_manager.AbsGlobalManager.registerManagerAsync}
  void register<T extends AbsWithLifeCycle>(AbsLifeCycleFactory<T> builder) =>
      registerManagerAsync<T>(builder);

  /// {@macro act_global_manager.AbsGlobalManager.manageAndVerifyState}
  bool advanceTo(Enum state) => tryAdvanceToState(state);

  /// {@macro act_global_manager.AbsGlobalManager.getGlobalManagerStates}
  List<Enum> get statesOfTheApp => getGlobalManagerStates();

  /// The managers which have been registered and initialized.
  List<AbsWithLifeCycle> get managersOfTheApp => registeredManagers;

  /// The managers which have been registered and which depend on the UI.
  List<AbsWithLifeCycleAndUi> get uiManagersOfTheApp =>
      registeredManagers.whereType<AbsWithLifeCycleAndUi>().toList(growable: false);
}
