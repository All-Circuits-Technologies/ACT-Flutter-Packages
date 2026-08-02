// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

/// A manager which says whether it has been initialised.
class _Manager extends AbsWithLifeCycle {
  bool initialised = false;

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    initialised = true;
  }
}

/// A manager whose initialisation fails.
class _FailingManager extends AbsWithLifeCycle {
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    throw ActMissingConfigException("serverUrl");
  }
}

/// Another manager, only used as a declared dependency.
class _OtherManager extends AbsWithLifeCycle {}

/// A factory which declares no dependency.
class _ManagerFactory extends AbsLifeCycleFactory<_Manager> {
  const _ManagerFactory() : super(_Manager.new);

  @override
  Iterable<Type> dependsOn() => const [];
}

/// A factory which declares a dependency on another manager.
class _DependentManagerFactory extends AbsLifeCycleFactory<_Manager> {
  const _DependentManagerFactory() : super(_Manager.new);

  @override
  Iterable<Type> dependsOn() => const [_OtherManager];
}

/// A factory whose manager fails to initialise.
class _FailingManagerFactory extends AbsLifeCycleFactory<_FailingManager> {
  const _FailingManagerFactory() : super(_FailingManager.new);

  @override
  Iterable<Type> dependsOn() => const [];
}

void main() {
  group("AbsLifeCycleFactory.asyncFactory", () {
    test("returns the manager built by the factory", () async {
      const factory = _ManagerFactory();

      expect(await factory.asyncFactory(), isA<_Manager>());
    });

    test("initialises the manager before returning it", () async {
      const factory = _ManagerFactory();

      final manager = await factory.asyncFactory();

      expect(manager.initialised, isTrue);
    });

    test("builds a new manager at every call", () async {
      const factory = _ManagerFactory();

      final manager = await factory.asyncFactory();
      final otherManager = await factory.asyncFactory();

      expect(manager, isNot(same(otherManager)));
    });

    test("lets the failure of an initialisation reach the caller", () async {
      const factory = _FailingManagerFactory();

      await expectLater(factory.asyncFactory(), throwsA(isA<ActMissingConfigException>()));
    });
  });

  group("AbsLifeCycleFactory.factory", () {
    test("builds a manager which has not been initialised yet", () {
      const factory = _ManagerFactory();

      expect(factory.factory().initialised, isFalse);
    });
  });

  group("AbsLifeCycleFactory.dependsOn", () {
    test("returns nothing when the manager depends on no other one", () {
      const factory = _ManagerFactory();

      expect(factory.dependsOn(), isEmpty);
    });

    test("returns the types the manager depends on", () {
      const factory = _DependentManagerFactory();

      expect(factory.dependsOn(), [_OtherManager]);
    });
  });
}
