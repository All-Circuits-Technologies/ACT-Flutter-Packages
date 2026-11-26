// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_global_manager/act_dart_global_manager.dart';
import 'package:act_dart_life_cycle/act_dart_life_cycle.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:test/test.dart';

import '../fakes/fake_global_managers.dart';
import '../fakes/fake_managers.dart';

/// A manager whose initialization gives the hand back several times before it completes.
///
/// A manager which depends on this one has to wait for it, and would otherwise be initialized
/// first. No delay is waited on, only the microtasks of the initialization are given the hand.
class _SlowManager extends FakeManager {
  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    for (var step = 0; step < 5; step++) {
      await Future<void>.microtask(() {});
    }

    await super.initLifeCycle();
  }
}

/// A state which is not one of the states of the application.
enum _OtherState {
  /// The only state
  other,
}

void main() {
  group("AbsGlobalManager", () {
    test("is a manager with a life cycle", () {
      expect(FakeGlobalManager(), isA<AbsWithLifeCycle>());
    });

    test("is the instance of the application it has set itself as", () {
      final manager = FakeGlobalManager();

      expect(AbsGlobalManager.instance, same(manager));
    });

    test("owns a get it instance of its own the managers are registered in", () {
      final manager = FakeGlobalManager();

      expect(manager.managers, isA<GetIt>());
      expect(manager.managers, isNot(same(GetIt.instance)));
    });

    test("reports whether the application has been built in release mode", () {
      expect(FakeGlobalManager().isReleaseMode, isFalse);
    });

    test("gives a logger which is ready before the managers are", () {
      final manager = FakeGlobalManager();

      expect(manager.defaultLogger, isA<MixinActLogger>());
    });

    test("goes through the states of an application without a view", () {
      expect(FakeGlobalManager().statesOfTheApp, GlobalManagerState.values);
    });
  });

  group("AbsGlobalManager.initLifeCycle", () {
    test("initializes the managers it registers", () async {
      final registered = FakeManager();
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeManagerBuilder(registered)),
      );

      await manager.initLifeCycle();

      expect(registered.initCount, 1);
    });

    test("makes the managers it registers reachable", () async {
      final registered = FakeManager();
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeManagerBuilder(registered)),
      );

      await manager.initLifeCycle();

      expect(globalGetIt().get<FakeManager>(), same(registered));
    });

    test("keeps the managers it registers", () async {
      final registered = FakeManager();
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeManagerBuilder(registered)),
      );

      await manager.initLifeCycle();

      expect(manager.managersOfTheApp, [registered]);
    });

    test("waits for every manager to be ready", () async {
      final first = FakeManager();
      final second = FakeDependentManager();
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async => globalManager
          ..register(FakeManagerBuilder(first))
          ..register(FakeDependentManagerBuilder(second)),
      );

      await manager.initLifeCycle();

      expect(manager.managers.allReadySync(), isTrue);
      expect(first.initCount, 1);
      expect(second.initCount, 1);
    });

    test("reaches its last state", () async {
      final manager = FakeGlobalManager();

      await manager.initLifeCycle();

      expect(manager.advanceTo(GlobalManagerState.allReady), isFalse);
    });

    test("registers the managers only once", () async {
      final registered = FakeManager();
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeManagerBuilder(registered)),
      );
      await manager.initLifeCycle();

      await manager.initLifeCycle();

      expect(registered.initCount, 1);
    });

    test("accepts an application which registers no manager", () async {
      final manager = FakeGlobalManager();

      await expectLater(manager.initLifeCycle(), completes);
      expect(manager.managersOfTheApp, isEmpty);
    });

    test("initializes a manager after the ones it depends on", () async {
      final dependency = _SlowManager();
      final dependent = FakeDependentManager();
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async => globalManager
          ..register(FakeManagerBuilder(dependency))
          ..register(FakeDependentManagerBuilder(dependent, dependencies: [FakeManager])),
      );

      await manager.initLifeCycle();

      expect(manager.managersOfTheApp, [dependency, dependent]);
    });

    test("registers a manager before the ones it depends on", () async {
      final dependency = FakeManager();
      final dependent = FakeDependentManager();
      final manager = FakeGlobalManager(
        // The dependent is registered first, before the manager it depends on: the registration
        // order does not have to follow the dependencies.
        onRegisterManagers: (globalManager) async => globalManager
          ..register(FakeDependentManagerBuilder(dependent, dependencies: [FakeManager]))
          ..register(FakeManagerBuilder(dependency)),
      );

      await manager.initLifeCycle();

      expect(dependency.initCount, 1);
      expect(dependent.initCount, 1);
    });

    test("crashes when a manager depends on one which is never registered", () async {
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async => globalManager.register(
          FakeDependentManagerBuilder(FakeDependentManager(), dependencies: [FakeManager]),
        ),
      );

      await expectLater(manager.initLifeCycle(), throwsA(isA<AssertionError>()));
    });

    test("crashes when the same manager is registered twice", () async {
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async => globalManager
          ..register(FakeManagerBuilder(FakeManager()))
          ..register(FakeManagerBuilder(FakeManager())),
      );

      await expectLater(manager.initLifeCycle(), throwsA(isA<AssertionError>()));
    });
  });

  group("AbsGlobalManager.tryAdvanceToState", () {
    test("refuses a state which has already been reached", () async {
      final manager = FakeGlobalManager();
      await manager.initLifeCycle();

      expect(manager.advanceTo(GlobalManagerState.notCreated), isFalse);
    });

    test("refuses a state which is not one of the application", () async {
      final manager = FakeGlobalManager();
      await manager.initLifeCycle();

      expect(manager.advanceTo(_OtherState.other), isFalse);
    });
  });

  group("AbsGlobalManager.disposeLifeCycle", () {
    test("disposes the managers it registered", () async {
      final registered = FakeManager();
      final manager = FakeGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeManagerBuilder(registered)),
      );
      await manager.initLifeCycle();

      await manager.disposeLifeCycle();

      expect(registered.disposeCount, 1);
    });

    test("accepts a manager which has never been initialized", () async {
      await expectLater(FakeGlobalManager().disposeLifeCycle(), completes);
    });
  });

  group("globalGetIt", () {
    test("gives the get it instance of the global manager", () {
      final manager = FakeGlobalManager();

      expect(globalGetIt(), same(manager.managers));
    });
  });

  group("appLogger", () {
    test("gives the default logger of the global manager", () {
      final manager = FakeGlobalManager();

      expect(appLogger(), same(manager.defaultLogger));
    });
  });
}
