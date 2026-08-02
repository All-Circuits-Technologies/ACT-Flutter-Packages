// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FakeGlobalManager", () {
    late FakeGlobalManager globalManager;

    tearDown(() => globalManager.reset());

    test("becomes the global manager of the application", () {
      globalManager = FakeGlobalManager.install();

      expect(AbsGlobalManager.instance, same(globalManager));
    });

    test("serves a silent logger when the test gives none", () {
      globalManager = FakeGlobalManager.install();

      expect(appLogger(), isA<SilentLogger>());
    });

    test("serves the logger of the test through the shortcut of the application", () {
      final logger = FakeLogger();

      globalManager = FakeGlobalManager.install(logger: logger);

      appLogger().w("something went wrong");
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("replaces the manager of the previous test", () {
      final previous = FakeGlobalManager.install();

      globalManager = FakeGlobalManager.install();

      expect(AbsGlobalManager.instance, isNot(same(previous)));
    });

    test("makes the managers it registers reachable through the shortcut", () async {
      globalManager = FakeGlobalManager.install();

      globalManager.register(_CounterBuilder());
      await globalManager.allReady();

      expect(globalGetIt().get<_Counter>().initCount, 1);
    });

    test("forgets the registered managers when it is reset", () async {
      globalManager = FakeGlobalManager.install();
      globalManager.register(_CounterBuilder());
      await globalManager.allReady();

      await globalManager.reset();

      expect(globalGetIt().isRegistered<_Counter>(), isFalse);
    });
  });
}

/// A manager which counts the times it has been initialized.
class _Counter extends AbsWithLifeCycle {
  /// The number of times the manager has been initialized.
  int initCount = 0;

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    initCount++;
  }
}

/// The builder of the manager the test registers.
class _CounterBuilder extends AbsLifeCycleFactory<_Counter> {
  /// Class constructor.
  _CounterBuilder() : super(_Counter.new);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => const [];
}
